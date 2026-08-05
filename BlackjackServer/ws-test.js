// End-to-end test of the Blackjack multiplayer lobby system.
// Requires the server running on 127.0.0.1:8080.
//
// Covers:
//  - REST: create + list lobbies
//  - WebSocket: join a specific lobby /ws/lobby/:id
//  - A full round (deal, turn order, settlement) and a next-round restart
//  - Multi-lobby isolation (a round in lobby 1 never leaks to lobby 2)
//
// Uses Node >= 22's built-in fetch + WebSocket.
"use strict";

const BASE = "http://127.0.0.1:8080";
const failure = [];

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }
function check(label, cond, detail = "") {
  console.log(`${cond ? "PASS" : "FAIL"}: ${label}${detail ? " — " + detail : ""}`);
  if (!cond) failure.push(label);
}

async function httpJSON(path, opts = {}) {
  const res = await fetch(BASE + path, opts);
  if (!res.ok) throw new Error(`HTTP ${res.status} on ${path}: ${await res.text()}`);
  return res.json();
}

async function createLobby(name) {
  return httpJSON("/lobbies", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name }),
  });
}

// Sends {type:"join"} and waits for a welcome or an error.
async function makeClient(lobbyID, name) {
  const ws = new WebSocket(`ws://127.0.0.1:8080/ws/lobby/${lobbyID}`);
  const c = {
      name, ws, id: null, lastState: null, sawDeal2: false,
      error: null, onTurn: null, statesReceived: 0, firstDealingState: null,
    };
    ws.onmessage = (ev) => {
      let msg;
      try { msg = JSON.parse(ev.data); } catch { return; }
      if (msg.type === "welcome") c.id = msg.playerID;
      if (msg.type === "error") c.error = msg.message;
      if (msg.type === "state") {
        const s = msg.state;
        c.lastState = s;
        c.statesReceived += 1;
        if (s.phase === "dealing" && (s.players || []).every((p) => p.hand.length === 2)) {
          c.sawDeal2 = true;
          if (!c.firstDealingState) c.firstDealingState = s;
        }
        if (s.phase === "dealing" && s.activePlayerID === c.id) {
          const me = (s.players || []).find((p) => p.id === c.id);
          if (me && me.status === "playing" && c.onTurn) c.onTurn(me, s);
        }
    }
  };
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = () => rej(new Error("ws open failed")); });
  ws.send(JSON.stringify({ type: "join", name }));
  // Wait for welcome (or a join error).
  for (let i = 0; i < 50 && !c.id && !c.error; i++) await sleep(50);
  c.send = (m) => ws.send(JSON.stringify(m));
  return c;
}

// Auto-play: hit until score > 17, then stand.
function autoStrategy(client) {
  client.onTurn = (me) => {
    client.send(me.score > 17 ? { type: "stand" } : { type: "hit" });
  };
}

async function waitForSettled(client, deadlineMs = 12000) {
  const end = Date.now() + deadlineMs;
  while (Date.now() < end) {
    const s = client.lastState;
    if (s && s.phase === "settled") return s;
    await sleep(120);
  }
  return null;
}

async function main() {
  // 1. REST: create + list.
  const l1 = await createLobby("Тест 1");
  check("create lobby 1 (named)", !!l1.id && l1.name === "Тест 1", JSON.stringify(l1));
  const l2 = await createLobby("Тест 2");
  check("create lobby 2", !!l2.id && l2.name === "Тест 2");
  const listAfter = await httpJSON("/lobbies");
  const ids = listAfter.map((l) => l.id);
  check("list contains both lobbies", ids.includes(l1.id) && ids.includes(l2.id), `count=${listAfter.length}`);

  // 2. Two clients join lobby 1.
  const A = await makeClient(l1.id, "Гравець А");
  const B = await makeClient(l1.id, "Гравець Б");
  check("A welcome + sees itself at the table",
    !!A.id && A.lastState?.players?.some((p) => p.id === A.id),
    `players=${A.lastState?.players?.length}`);
  check("B welcome + state has 2 players", !!B.id && B.lastState?.players?.length === 2, `players=${B.lastState?.players?.length}`);

  // 3. Play a full round in lobby 1.
  autoStrategy(A);
  autoStrategy(B);
  A.send({ type: "startRound" });
  const settled = await waitForSettled(A);
  check("round settled", !!settled);
  const resultOk = settled && settled.players.every((p) =>
    ["won", "lost", "push", "blackjack"].includes(p.status));
  check("RESULT: all players settled with a result", !!resultOk,
    settled ? settled.players.map((p) => `${p.name}:${p.score}/${p.status}`).join(", ") : "");

  // 3b. Card/score masking: mid-round nobody sees opponents' cards or points.
  const aDeal = A.firstDealingState;
  const aOwn = aDeal?.players?.find((p) => p.id === A.id);
  const aSeesB = aDeal?.players?.find((p) => p.id === B.id);
  check("masking: A sees own cards and points", !!aOwn && aOwn.hand.length > 0 && aOwn.hand.every((c) => !c.isHidden) && aOwn.score > 0);
  check("masking: A cannot see B's cards or points",
    !!aSeesB && aSeesB.hand.length > 0 && aSeesB.hand.every((c) => c.isHidden) && aSeesB.score === 0);
  check("masking: dealer fully hidden mid-round",
    !!aDeal && aDeal.dealerHand.length > 0 && aDeal.dealerHand.every((c) => c.isHidden) && aDeal.dealerScore === 0);
  const bDeal = B.firstDealingState;
  const bSeesA = bDeal?.players?.find((p) => p.id === A.id);
  check("masking: B cannot see A's cards either", !!bSeesA && bSeesA.hand.every((c) => c.isHidden) && bSeesA.score === 0);

  // 3c. At settlement everything is revealed.
  const revealed = settled && settled.players.every((p) => p.hand.length > 0 && p.hand.every((c) => !c.isHidden) && p.score > 0)
    && settled.dealerHand.length > 0 && settled.dealerHand.every((c) => !c.isHidden) && settled.dealerScore > 0;
  check("settled: all cards and scores revealed", !!revealed);

  // 4. Next round restart in lobby 1.
  A.sawDeal2 = false;
  A.send({ type: "startRound" });
  await sleep(700);
  check("NEXT ROUND: re-deal seen with 2 cards each", A.sawDeal2);

  // 5. Clean up lobby-1 players → the now-empty lobby is deleted at once.
  A.send({ type: "leave" });
  B.send({ type: "leave" });
  await sleep(300);
  A.ws.close();
  B.ws.close();
  const afterAB = await httpJSON("/lobbies");
  check("lobby 1 removed once empty", !afterAB.some((l) => l.id === l1.id),
    `listed=${afterAB.map((l) => l.name).join(", ") || "none"}`);

  // 6. Multi-lobby isolation.
  // C sits alone in lobby 2; D plays a round in a fresh lobby 3. A round in
  // lobby 3 must never leak to lobby 2 (and vice versa).
  const C = await makeClient(l2.id, "Гравець Ц");
  check("C welcome + alone in lobby 2", !!C.id && C.lastState?.phase === "lobby" && C.lastState?.players?.length === 1);

  const before = JSON.stringify(C.lastState);
  const l3 = await createLobby("Тест 3");
  const D = await makeClient(l3.id, "Гравець Д");
  check("D welcome + alone in lobby 3", !!D.id && D.lastState?.players?.length === 1);

  autoStrategy(D);
  D.send({ type: "startRound" });
  const settledD = await waitForSettled(D, 12000);
  check("D round in lobby 3 settled", !!settledD);

  // C (lobby 2) must not have observed any of it.
  const after = JSON.stringify(C.lastState);
  check("isolation: lobby 2 client saw no lobby-3 state", before === after,
    C.lastState ? `${C.lastState.phase}/${C.lastState.players.length} players` : "no state");

  D.send({ type: "leave" });
  C.send({ type: "leave" });
  await sleep(300);
  D.ws.close();
  C.ws.close();

  // Every lobby is empty now → all removed from the list.
  const finalList = await httpJSON("/lobbies");
  check("all empty lobbies removed",
    !finalList.some((l) => l.id === l1.id || l.id === l2.id || l.id === l3.id),
    `remaining=${finalList.map((l) => l.name).join(", ") || "none"}`);

  // 7. Single player leaves MID-ROUND: the room must not be stranded with a
  // disconnected "ghost" player (that lobby used to linger forever).
  const soloRoom = await createLobby("Соло гравець");
  const S = await makeClient(soloRoom.id, "Соло");
  check("solo welcome + alone", !!S.id && S.lastState?.players?.length === 1);
  S.send({ type: "startRound" }); // deal starts; the round only auto-settles
  // if S's initial two cards are a natural blackjack (~5% of shuffles), so the
  // exact phase at this instant is not deterministic — assert the deal itself.
  await sleep(300);
  check("solo round started (sole player dealt 2 cards)",
    (S.lastState?.players?.[0]?.hand?.length ?? 0) === 2,
    `phase=${S.lastState?.phase ?? "none"}`);
  S.send({ type: "leave" }); // the only player walks away mid-round
  await sleep(300);
  S.ws.close();
  const afterSolo = await httpJSON("/lobbies");
  check("solo lobby removed after last player leaves mid-round",
    !afterSolo.some((l) => l.id === soloRoom.id),
    `listed=${afterSolo.map((l) => l.name).join(", ") || "none"}`);

  if (failure.length) {
    console.log("\nDONE: " + failure.length + " check(s) failed");
    process.exit(1);
  }
  console.log("\nDONE: ALL TESTS PASSED");
}

main().catch((e) => { console.error("TEST CRASHED:", e); process.exit(1); });