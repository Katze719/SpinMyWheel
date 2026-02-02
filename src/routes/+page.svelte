<script lang="ts">
  const SEGMENT_COLORS = [
    "#e21b3c",
    "#1368ce",
    "#d89e00",
    "#26890c",
    "#e84a5f",
    "#1a67a3",
    "#f0a32e",
    "#2d9d78",
    "#c73659",
    "#4a90d9",
    "#e8c547",
    "#3db88a",
  ];

  let entries = $state<string[]>([]);
  let newEntry = $state("");
  let removeWinnerAfterSpin = $state(false);
  let isSpinning = $state(false);
  let winner = $state<string | null>(null);
  let rotation = $state(0);
  let spinTransition = $state("");
  let wheelEl = $state<SVGSVGElement | null>(null);
  let confettiPieces = $state<Array<{ id: number; left: number; delay: number; duration: number; color: string; size: number; rot: number }>>([]);
  let showWinnerEffect = $state(false);
  let showRipple = $state(false);
  let showSparkles = $state(false);
  let showShine = $state(false);
  let sparkles = $state<Array<{ id: number; x: number; y: number; dx: number; dy: number; delay: number }>>([]);
  let spinIntensity = $state(0);
  let intensityIntervalId = 0;
  let intensityRafId = 0;

  const CONFETTI_COLORS = ["#e21b3c", "#1368ce", "#d89e00", "#26890c", "#f0a32e", "#2d9d78", "#e8c547", "#c73659"];

  function addEntry() {
    const name = newEntry.trim();
    if (name && !entries.includes(name)) {
      entries = [...entries, name];
      newEntry = "";
      winner = null;
    }
  }

  function removeEntry(index: number) {
    entries = entries.filter((_, i) => i !== index);
    winner = null;
  }

  function spin() {
    if (entries.length === 0 || isSpinning) return;
    winner = null;
    isSpinning = true;
    if (intensityIntervalId) clearInterval(intensityIntervalId);
    if (intensityRafId) cancelAnimationFrame(intensityRafId);
    const startTime = Date.now();
    intensityIntervalId = setInterval(() => {
      const t = (Date.now() - startTime) / 5000;
      spinIntensity = t >= 1 ? 1 : t;
      if (t >= 1 && intensityIntervalId) {
        clearInterval(intensityIntervalId);
        intensityIntervalId = 0;
      }
    }, 50);

    const n = entries.length;
    const randomIndex = Math.floor(Math.random() * n);
    const segmentAngle = 360 / n;
    // Segment i: Mitte bei 90 + (i+0.5)*segmentAngle (SVG: 0°=rechts, 90°=unten, 270°=oben/Norden).
    const segmentCenterDeg = 90 + (randomIndex + 0.5) * segmentAngle;
    // Pfeil oben = 270°. CSS rotate(R): positiv = Uhrzeigersinn → Punkt θ landet bei θ−R. Damit Mitte oben: segmentCenterDeg − R = 270 → R = segmentCenterDeg − 270.
    const currentMod = ((rotation % 360) + 360) % 360;
    const targetMod = (segmentCenterDeg - 270 + 360) % 360;
    const baseAngle = (targetMod - currentMod + 360) % 360;
    const fullSpins = 6 + Math.random() * 3;
    const targetRotation = 360 * fullSpins + baseAngle;

    const duration = 5000;
    spinTransition = `transform ${duration}ms cubic-bezier(0.17, 0.67, 0.12, 0.99)`;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        rotation = rotation + targetRotation;
      });
    });
    setTimeout(() => {
      if (intensityIntervalId) {
        clearInterval(intensityIntervalId);
        intensityIntervalId = 0;
      }
      spinIntensity = 1;
      isSpinning = false;
      spinTransition = "";
      const R = ((rotation % 360) + 360) % 360;
      const nE = entries.length;
      const segAngle = 360 / nE;
      const theta = (270 - R + 360) % 360;
      const winnerIndex = (Math.floor((theta - 90) / segAngle) % nE + nE) % nE;
      const drawnWinner = entries[winnerIndex];
      winner = drawnWinner;
      if (removeWinnerAfterSpin) {
        entries = entries.filter((name) => name !== drawnWinner);
      }
      // Normalisiere rotation für nächsten Spin (verhindert overflow bei vielen Spins)
      rotation = R;
      showWinnerEffect = true;
      showRipple = true;
      showShine = true;
      const fadeStart = Date.now();
      function fadeIntensity() {
        const elapsed = Date.now() - fadeStart;
        const t = elapsed / 1500;
        if (t >= 1) {
          spinIntensity = 0;
          return;
        }
        spinIntensity = 1 - t;
        intensityRafId = requestAnimationFrame(fadeIntensity);
      }
      intensityRafId = requestAnimationFrame(fadeIntensity);
      confettiPieces = Array.from({ length: 50 }, (_, i) => ({
        id: i,
        left: Math.random() * 100,
        delay: Math.random() * 400,
        duration: 2500 + Math.random() * 1500,
        color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
        size: 6 + Math.random() * 8,
        rot: Math.random() * 720 - 360,
      }));
      sparkles = Array.from({ length: 24 }, (_, i) => {
        const angle = (i / 24) * Math.PI * 2 + Math.random() * 0.5;
        const dist = 80 + Math.random() * 120;
        return {
          id: i,
          x: 50,
          y: 45,
          dx: Math.cos(angle) * dist,
          dy: Math.sin(angle) * dist,
          delay: Math.random() * 150,
        };
      });
      showSparkles = true;
      setTimeout(() => {
        confettiPieces = [];
      }, 4500);
      setTimeout(() => {
        showRipple = false;
        showShine = false;
        showSparkles = false;
      }, 2000);
    }, duration);
  }

  function getSegmentPath(
    cx: number,
    cy: number,
    r: number,
    startAngleDeg: number,
    endAngleDeg: number,
  ): string {
    const start = (startAngleDeg * Math.PI) / 180;
    const end = (endAngleDeg * Math.PI) / 180;
    const x1 = cx + r * Math.cos(start);
    const y1 = cy + r * Math.sin(start);
    const x2 = cx + r * Math.cos(end);
    const y2 = cy + r * Math.sin(end);
    const large = endAngleDeg - startAngleDeg > 180 ? 1 : 0;
    return `M ${cx} ${cy} L ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2} Z`;
  }
</script>

<main class="spin-wheel-app" style="--spin-intensity: {spinIntensity}">
  <div class="bg-ambient" aria-hidden="true">
    <div class="bg-gradient"></div>
    <div class="bg-blob bg-blob-1"></div>
    <div class="bg-blob bg-blob-2"></div>
    <div class="bg-blob bg-blob-3"></div>
    <div class="bg-blob bg-blob-4"></div>
    <div class="bg-blob bg-blob-5"></div>
  </div>
  <div class="app-content">
  <h1>Spin My Wheel</h1>
  <p class="subtitle">Add names and spin the wheel</p>

  <section class="entries-section">
    <div class="add-row">
      <input
        type="text"
        placeholder="Enter a name..."
        bind:value={newEntry}
        onkeydown={(e) => e.key === "Enter" && addEntry()}
        disabled={isSpinning}
      />
      <button
        type="button"
        onclick={addEntry}
        disabled={isSpinning || !newEntry.trim()}
      >
        Add
      </button>
    </div>
    <ul class="entries-list">
      {#each entries as name, i}
        <li>
          <span>{name}</span>
          <button
            type="button"
            class="remove"
            onclick={() => removeEntry(i)}
            disabled={isSpinning}
            title="Remove"
            aria-label="Remove"
          >
            ×
          </button>
        </li>
      {/each}
    </ul>
    <div class="option-row">
      <span class="option-label">Remove drawn names</span>
      <button
        type="button"
        class="toggle-btn"
        class:on={removeWinnerAfterSpin}
        class:off={!removeWinnerAfterSpin}
        disabled={isSpinning}
        onclick={() => (removeWinnerAfterSpin = !removeWinnerAfterSpin)}
        aria-pressed={removeWinnerAfterSpin}
      >
        <span class="toggle-off">Off</span>
        <span class="toggle-on">On</span>
      </button>
    </div>
  </section>

  <section class="wheel-section">
    <div class="wheel-wrapper">
      {#if entries.length > 0}
        <div class="wheel-inner" class:wheel-stop={winner !== null && !isSpinning}>
          <svg
            class="wheel"
            viewBox="0 0 320 320"
            preserveAspectRatio="xMidYMid meet"
            bind:this={wheelEl}
            style="transform: rotate({rotation}deg); transition: {spinTransition}"
            aria-hidden="true"
          >
          <g transform="translate(160, 160)">
            {#each entries as name, i}
              {@const n = entries.length}
              {@const startDeg = 90 + (i * 360) / n}
              {@const endDeg = 90 + ((i + 1) * 360) / n}
              {#if n === 1}
                <circle
                  cx="0"
                  cy="0"
                  r="140"
                  fill={SEGMENT_COLORS[i % SEGMENT_COLORS.length]}
                  stroke="#fff"
                  stroke-width="1.5"
                />
              {:else}
                <path
                  d={getSegmentPath(0, 0, 140, startDeg, endDeg)}
                  fill={SEGMENT_COLORS[i % SEGMENT_COLORS.length]}
                  stroke="#fff"
                  stroke-width="1.5"
                />
              {/if}
              {@const midDeg = (startDeg + endDeg) / 2}
              {@const labelR = 95}
              {@const rad = (midDeg * Math.PI) / 180}
              {@const tx = labelR * Math.cos(rad)}
              {@const ty = labelR * Math.sin(rad)}
              {@const textRot =
                midDeg > 90 && midDeg < 270 ? midDeg + 180 : midDeg}
              <text
                x={tx}
                y={ty}
                text-anchor="middle"
                dominant-baseline="middle"
                transform="rotate({textRot} {tx} {ty})"
                class="segment-label"
              >
                {name.length > 12 ? name.slice(0, 10) + "…" : name}
              </text>
            {/each}
          </g>
        </svg>
        </div>
      {:else}
        <div class="wheel-placeholder">
          <span>Wheel appears when you add names</span>
        </div>
      {/if}
      {#if showRipple && winner}
        <div class="wheel-ripple" aria-hidden="true">
          <span class="ripple-ring"></span>
          <span class="ripple-ring"></span>
          <span class="ripple-ring"></span>
        </div>
      {/if}
      {#if showShine && winner}
        <div class="wheel-shine" aria-hidden="true"></div>
      {/if}
      <div class="pointer" class:pointer-bounce={winner !== null && !isSpinning} aria-hidden="true"></div>
    </div>

    <button
      type="button"
      class="spin-btn"
      onclick={spin}
      disabled={entries.length === 0 || isSpinning}
    >
      {isSpinning ? "Spinning…" : "Spin!"}
    </button>

    {#if winner !== null && !isSpinning}
      <div class="winner" class:winner-pop={showWinnerEffect} role="alert">
        <span class="winner-label">Winner:</span>
        <span class="winner-name">{winner}</span>
      </div>
    {/if}
  </section>
  </div>

  {#if confettiPieces.length > 0}
    <div class="confetti-overlay" aria-hidden="true">
      {#each confettiPieces as piece (piece.id)}
        <div
          class="confetti-piece"
          style="
            left: {piece.left}%;
            animation-delay: {piece.delay}ms;
            animation-duration: {piece.duration}ms;
            background: {piece.color};
            width: {piece.size}px;
            height: {piece.size * 0.6}px;
            --rot: {piece.rot}deg;
          "
        ></div>
      {/each}
    </div>
  {/if}

  {#if showSparkles && sparkles.length > 0}
    <div class="sparkles" aria-hidden="true">
      {#each sparkles as s (s.id)}
        <div
          class="sparkle"
          style="
            left: {s.x}%;
            top: {s.y}%;
            --dx: {s.dx}px;
            --dy: {s.dy}px;
            animation-delay: {s.delay}ms;
          "
        ></div>
      {/each}
    </div>
  {/if}
</main>
