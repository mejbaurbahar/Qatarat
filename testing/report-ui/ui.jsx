// Shared UI atoms — icons, pills, sparkline, donut, etc.
const { useState, useEffect, useMemo, useRef, useContext } = React;

// ─── Tooltip ─────────────────────────────────────────────────────────────
const TipCtx = React.createContext(() => {});
const TipProvider = ({ children }) => {
  const [tip, setTip] = useState(null);
  return (
    <TipCtx.Provider value={setTip}>
      {children}
      {tip && (
        <div style={{
          position: "fixed",
          left: Math.min(tip.x + 14, window.innerWidth - 240),
          top: tip.y + 14,
          zIndex: 1000, pointerEvents: "none",
          background: "color-mix(in oklch, var(--bg-2) 96%, transparent)",
          backdropFilter: "blur(12px) saturate(140%)",
          border: "1px solid var(--border-2)",
          padding: "8px 11px", borderRadius: 8,
          fontSize: 12, color: "var(--text)",
          fontFamily: "Geist",
          boxShadow: "0 12px 28px -10px rgba(0,0,0,.6), 0 0 0 1px rgba(255,255,255,.02) inset",
          minWidth: 110, maxWidth: 240,
          transform: "translateZ(0)",
        }}>
          {tip.content}
        </div>
      )}
    </TipCtx.Provider>
  );
};
const useTip = () => {
  const setTip = useContext(TipCtx);
  return useMemo(() => ({
    show: (e, content) => setTip({ x: e.clientX, y: e.clientY, content }),
    move: (e) => setTip(prev => prev ? { ...prev, x: e.clientX, y: e.clientY } : null),
    hide: () => setTip(null),
  }), [setTip]);
};

const TipRow = ({ label, value, color }) => (
  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 14, padding: "2px 0" }}>
    <span style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--text-3)", fontSize: 11.5 }}>
      {color && <span style={{ width: 7, height: 7, borderRadius: 2, background: color }} />}
      {label}
    </span>
    <span className="mono" style={{ fontSize: 11.5, color: "var(--text)" }}>{value}</span>
  </div>
);

// Tiny icon set — stroked, 16px
const Icon = ({ name, size = 16, strokeWidth = 1.6, ...rest }) => {
  const paths = {
    overview:   <><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></>,
    flows:      <><path d="M4 6h12M4 12h16M4 18h8"/><circle cx="20" cy="6" r="1.6" fill="currentColor"/><circle cx="20" cy="18" r="1.6" fill="currentColor"/></>,
    appium:     <><path d="M7 4v4M17 4v4M7 16v4M17 16v4"/><rect x="6" y="8" width="12" height="8" rx="2"/><path d="M10 12h4"/></>,
    pipeline:   <><circle cx="6" cy="6" r="2"/><circle cx="18" cy="18" r="2"/><circle cx="6" cy="18" r="2"/><path d="M6 8v8M8 6h8a4 4 0 0 1 4 4v6"/></>,
    history:    <><circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/></>,
    play:       <><polygon points="6 4 20 12 6 20 6 4" fill="currentColor" stroke="none"/></>,
    refresh:    <><path d="M3 12a9 9 0 0 1 15.5-6.3L21 8"/><path d="M21 4v4h-4"/><path d="M21 12a9 9 0 0 1-15.5 6.3L3 16"/><path d="M3 20v-4h4"/></>,
    branch:     <><circle cx="6" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="12" r="2"/><path d="M6 7v10M6 12h6a4 4 0 0 0 4-4"/></>,
    commit:     <><circle cx="12" cy="12" r="3.2"/><path d="M3 12h5.8M15.2 12H21"/></>,
    download:   <><path d="M12 4v12"/><path d="m7 11 5 5 5-5"/><path d="M4 20h16"/></>,
    filter:     <><path d="M4 5h16l-6 8v5l-4 2v-7L4 5z"/></>,
    search:     <><circle cx="11" cy="11" r="6"/><path d="m20 20-3.5-3.5"/></>,
    arrow:      <><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></>,
    clock:      <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    user:       <><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>,
    card:       <><rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/><path d="M7 15h3"/></>,
    bank:       <><path d="m12 3 9 4H3l9-4z"/><path d="M5 9v8M19 9v8M12 9v8"/><path d="M3 19h18"/></>,
    gift:       <><rect x="3" y="9" width="18" height="11" rx="1.5"/><path d="M3 13h18"/><path d="M12 9v11"/><path d="M8 9a3 3 0 1 1 4-3 3 3 0 1 1 4 3"/></>,
    repeat:     <><path d="M17 3l4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="M7 21l-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/></>,
    video:      <><rect x="3" y="6" width="13" height="12" rx="2"/><path d="m16 10 5-3v10l-5-3z"/></>,
    split:      <><path d="M3 7h6l4 5 4 5h4"/><path d="M3 17h6l4-5"/><path d="m17 4 4 3-4 3"/></>,
    phone:      <><rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M10 19h4"/></>,
    chevron:    <><path d="m9 6 6 6-6 6"/></>,
    check:      <><path d="m5 12 4 4 10-10"/></>,
    x:          <><path d="M6 6l12 12M18 6 6 18"/></>,
    bolt:       <><path d="M13 3 4 14h7l-1 7 9-11h-7l1-7z"/></>,
    leaf:       <><path d="M21 3c0 9-6 15-15 15a9 9 0 0 0 9-9c0-3 3-6 6-6z"/><path d="M6 18c2-5 6-8 11-9"/></>,
  };
  const node = paths[name];
  if (!node) return null;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
         strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...rest}>
      {node}
    </svg>
  );
};

const Pill = ({ kind = "pass", children, dot = true }) => (
  <span className={`pill ${kind}`}>{dot && <span className="d" />}{children}</span>
);

const StatusPill = ({ status }) => {
  const labels = { pass: "passed", fail: "failed", flaky: "flaky", idle: "idle", run: "running" };
  return <Pill kind={status}>{labels[status] || status}</Pill>;
};

// Animated count-up
function useCountUp(target, duration = 900) {
  const [v, setV] = useState(0);
  const ref = useRef();
  useEffect(() => {
    const start = performance.now();
    const from = ref.current ?? 0;
    let raf;
    const step = (t) => {
      const p = Math.min(1, (t - start) / duration);
      const eased = 1 - Math.pow(1 - p, 3);
      const value = from + (target - from) * eased;
      setV(value);
      if (p < 1) raf = requestAnimationFrame(step);
      else ref.current = target;
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, duration]);
  return v;
}

const Stat = ({ label, value, suffix = "", trend, color = "var(--text)", decimals = 0, sub }) => {
  const v = useCountUp(value);
  return (
    <div className="card" style={{ padding: 16, display: "flex", flexDirection: "column", gap: 6 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontSize: 11.5, color: "var(--text-3)", textTransform: "uppercase", letterSpacing: ".09em", fontWeight: 500 }}>{label}</span>
        {trend != null && (
          <span className="mono" style={{ fontSize: 11, color: trend >= 0 ? "var(--pass)" : "var(--fail)" }}>
            {trend >= 0 ? "▲" : "▼"} {Math.abs(trend).toFixed(1)}%
          </span>
        )}
      </div>
      <div style={{ fontSize: 30, fontWeight: 600, letterSpacing: "-0.02em", color, lineHeight: 1.05, fontFamily: "Geist" }}>
        {v.toFixed(decimals)}<span style={{ fontSize: 18, color: "var(--text-3)", marginLeft: 3, fontWeight: 500 }}>{suffix}</span>
      </div>
      {sub && <span style={{ fontSize: 12, color: "var(--text-3)" }}>{sub}</span>}
    </div>
  );
};

// Sparkline
const Sparkline = ({ data, color = "var(--accent)", height = 36, width = 120, fill = true, label = "value", format = (v) => v.toFixed(1), labelForIndex }) => {
  const max = Math.max(...data);
  const min = Math.min(...data);
  const range = Math.max(1, max - min);
  const stepX = width / (data.length - 1);
  const pts = data.map((v, i) => [i * stepX, height - ((v - min) / range) * (height - 4) - 2]);
  const path = pts.map((p, i) => `${i === 0 ? "M" : "L"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
  const area = `${path} L${width},${height} L0,${height} Z`;
  const id = useMemo(() => `sg-${Math.random().toString(36).slice(2, 7)}`, []);
  const [hoverIdx, setHoverIdx] = useState(null);
  const tip = useTip();
  const svgRef = useRef(null);

  const handleMove = (e) => {
    const rect = svgRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const idx = Math.max(0, Math.min(data.length - 1, Math.round(x / stepX)));
    setHoverIdx(idx);
    tip.show(e, (
      <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
        <div style={{ color: "var(--text-3)", fontSize: 11 }}>
          {labelForIndex ? labelForIndex(idx) : `Point ${idx + 1}`}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 7, fontSize: 13, fontFamily: "Geist Mono", color }}>
          <span style={{ width: 7, height: 7, borderRadius: 50, background: color }} />
          {format(data[idx])}
        </div>
        <div style={{ color: "var(--text-3)", fontSize: 10.5, textTransform: "uppercase", letterSpacing: ".08em" }}>{label}</div>
      </div>
    ));
  };

  return (
    <svg ref={svgRef} width={width} height={height} style={{ display: "block", cursor: "crosshair" }}
         onMouseMove={handleMove} onMouseLeave={() => { setHoverIdx(null); tip.hide(); }}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.32" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      {fill && <path d={area} fill={`url(#${id})`} />}
      <path d={path} fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
      {hoverIdx != null && (
        <>
          <line x1={pts[hoverIdx][0]} y1={0} x2={pts[hoverIdx][0]} y2={height}
                stroke="var(--border-2)" strokeWidth="1" strokeDasharray="2 3" />
          <circle cx={pts[hoverIdx][0]} cy={pts[hoverIdx][1]} r="4" fill={color}
                  stroke="var(--bg)" strokeWidth="2" />
        </>
      )}
      {hoverIdx == null && (
        <circle cx={pts[pts.length - 1][0]} cy={pts[pts.length - 1][1]} r="2.5" fill={color} />
      )}
    </svg>
  );
};

// Donut chart
const Donut = ({ segments, size = 140, thickness = 14, centerLabel, centerSub }) => {
  const total = segments.reduce((s, x) => s + x.value, 0);
  const r = size / 2 - thickness / 2;
  const c = 2 * Math.PI * r;
  const [hover, setHover] = useState(null);
  const tip = useTip();
  let offset = 0;
  return (
    <div style={{ position: "relative", width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--surface-3)" strokeWidth={thickness} />
        {segments.map((s, i) => {
          const len = (s.value / total) * c;
          const dasharray = `${len} ${c - len}`;
          const dashoffset = -offset;
          offset += len;
          const isHover = hover === i;
          const pct = ((s.value / total) * 100).toFixed(1);
          return (
            <circle key={i} cx={size / 2} cy={size / 2} r={r} fill="none"
                    stroke={s.color} strokeWidth={isHover ? thickness + 3 : thickness}
                    strokeDasharray={dasharray} strokeDashoffset={dashoffset}
                    strokeLinecap="butt"
                    style={{ transition: "stroke-width .15s ease, opacity .15s ease", opacity: hover != null && !isHover ? 0.45 : 1, cursor: "pointer" }}
                    onMouseEnter={(e) => { setHover(i); tip.show(e, (
                      <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 7, fontWeight: 500 }}>
                          <span style={{ width: 8, height: 8, borderRadius: 2, background: s.color }} />
                          {s.label || `Segment ${i+1}`}
                        </div>
                        <TipRow label="tests" value={s.value} />
                        <TipRow label="share" value={`${pct}%`} />
                      </div>
                    )); }}
                    onMouseMove={tip.move}
                    onMouseLeave={() => { setHover(null); tip.hide(); }} />
          );
        })}
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", textAlign: "center", pointerEvents: "none" }}>
        <div>
          <div style={{ fontSize: 24, fontWeight: 600, letterSpacing: "-0.02em" }}>{centerLabel}</div>
          {centerSub && <div style={{ fontSize: 11, color: "var(--text-3)", marginTop: 2, fontFamily: "Geist Mono", textTransform: "uppercase", letterSpacing: ".08em" }}>{centerSub}</div>}
        </div>
      </div>
    </div>
  );
};

// Bar chart for history
const BarChart = ({ data, height = 120 }) => {
  const max = Math.max(...data.map(d => d.total));
  const [hover, setHover] = useState(null);
  const tip = useTip();
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 3, height, padding: "4px 0" }}>
      {data.map((d, i) => {
        const totalH = (d.total / max) * height;
        const failH = (d.fail / max) * height;
        const flakyH = (d.flaky / max) * height;
        const passH = totalH - failH - flakyH;
        const rate = ((d.pass / d.total) * 100).toFixed(1);
        const isHover = hover === i;
        return (
          <div key={i}
               onMouseEnter={(e) => { setHover(i); tip.show(e, (
                  <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                    <div style={{ color: "var(--text)", fontWeight: 500, fontSize: 12.5 }}>{d.day === 0 ? "Today" : `${d.day} day${d.day===1?"":"s"} ago`}</div>
                    <div style={{ height: 1, background: "var(--border)", margin: "2px 0" }} />
                    <TipRow label="passed" value={d.pass} color="oklch(74% 0.18 155)" />
                    {d.flaky > 0 && <TipRow label="flaky" value={d.flaky} color="oklch(80% 0.16 75)" />}
                    {d.fail > 0 && <TipRow label="failed" value={d.fail} color="oklch(70% 0.22 18)" />}
                    <TipRow label="pass rate" value={`${rate}%`} />
                    <TipRow label="duration" value={fmtDur(d.duration)} />
                  </div>
               )); }}
               onMouseMove={tip.move}
               onMouseLeave={() => { setHover(null); tip.hide(); }}
               style={{ flex: 1, display: "flex", flexDirection: "column-reverse", gap: 1, minWidth: 6, cursor: "pointer", opacity: hover != null && !isHover ? 0.55 : 1, transition: "opacity .15s ease" }}>
            <div style={{ height: passH, background: "var(--pass)", borderRadius: "1px 1px 0 0", opacity: .9 }} />
            {flakyH > 0 && <div style={{ height: flakyH, background: "var(--flaky)", opacity: .9 }} />}
            {failH > 0 && <div style={{ height: failH, background: "var(--fail)", borderRadius: "1px 1px 0 0", opacity: .9 }} />}
          </div>
        );
      })}
    </div>
  );
};

// Coverage bar
const CoverageBar = ({ pass, flaky = 0, fail = 0, height = 8 }) => {
  const total = pass + flaky + fail || 1;
  return (
    <div style={{ display: "flex", height, borderRadius: 999, overflow: "hidden", background: "var(--surface-3)" }}>
      <div style={{ width: `${(pass / total) * 100}%`, background: "var(--pass)" }} />
      <div style={{ width: `${(flaky / total) * 100}%`, background: "var(--flaky)" }} />
      <div style={{ width: `${(fail / total) * 100}%`, background: "var(--fail)" }} />
    </div>
  );
};

// Formatters
const fmtDur = (sec) => {
  if (sec < 60) return `${sec.toFixed(sec < 10 ? 1 : 0)}s`;
  const m = Math.floor(sec / 60);
  const s = Math.round(sec % 60);
  return `${m}m ${s.toString().padStart(2, "0")}s`;
};

Object.assign(window, { Icon, Pill, StatusPill, Stat, Sparkline, Donut, BarChart, CoverageBar, fmtDur, useCountUp, TipProvider, useTip, TipRow });
