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
  let isSpinning = $state(false);
  let winner = $state<string | null>(null);
  let rotation = $state(0);
  let spinTransition = $state("");
  let wheelEl = $state<SVGSVGElement | null>(null);

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

    const n = entries.length;
    const randomIndex = Math.floor(Math.random() * n);
    const segmentAngle = 360 / n;
    const segmentCenterDeg = 90 + (randomIndex + 0.5) * segmentAngle;
    let baseAngle = 270 - segmentCenterDeg;
    if (baseAngle < 0) baseAngle += 360;
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
      isSpinning = false;
      winner = entries[randomIndex];
      spinTransition = "";
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

<main class="spin-wheel-app">
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
    {#if entries.length === 0}
      <p class="hint">Add at least one name, then spin.</p>
    {/if}
  </section>

  <section class="wheel-section">
    <div class="wheel-wrapper">
      {#if entries.length > 0}
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
              <path
                d={getSegmentPath(0, 0, 140, startDeg, endDeg)}
                fill={SEGMENT_COLORS[i % SEGMENT_COLORS.length]}
                stroke="#fff"
                stroke-width="1.5"
              />
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
      {:else}
        <div class="wheel-placeholder">
          <span>Wheel appears when you add names</span>
        </div>
      {/if}
      <div class="pointer" aria-hidden="true"></div>
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
      <div class="winner" role="alert">
        <span class="winner-label">Winner:</span>
        <span class="winner-name">{winner}</span>
      </div>
    {/if}
  </section>
</main>
