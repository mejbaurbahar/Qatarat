// Appium deep tests view — file-based grouping
const AppiumView = () => {
  const { APPIUM_TESTS } = window.QATARAT_DATA;
  const [expanded, setExpanded] = useState(() => new Set(APPIUM_TESTS.map(f => f.file)));
  const [filter, setFilter] = useState("all");

  const allTests = APPIUM_TESTS.flatMap(f => f.tests);
  const counts = allTests.reduce((acc, t) => { acc[t.status] = (acc[t.status] || 0) + 1; return acc; }, {});

  const toggle = (file) => {
    setExpanded(prev => {
      const n = new Set(prev);
      if (n.has(file)) n.delete(file); else n.add(file);
      return n;
    });
  };

  const visibleTests = (file) => file.tests.filter(t => filter === "all" || t.status === filter);

  return (
    <div className="grid" style={{ gap: 18 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "end" }}>
        <div>
          <h1 className="h1" style={{ fontSize: 22 }}>Appium deep tests</h1>
          <p className="lead" style={{ fontSize: 13 }}>Python · pytest · appium-flutter-driver. Lower-level assertions on payment SDKs, BNPL, subscriptions, and account flows.</p>
        </div>
        <div className="seg">
          {[
            ["all", `All ${allTests.length}`],
            ["pass", `Passed ${counts.pass || 0}`],
            ["flaky", `Flaky ${counts.flaky || 0}`],
            ["fail", `Failed ${counts.fail || 0}`],
          ].map(([v, l]) => (
            <button key={v} className={filter === v ? "on" : ""} onClick={() => setFilter(v)}>{l}</button>
          ))}
        </div>
      </div>

      <div className="grid" style={{ gap: 12 }}>
        {APPIUM_TESTS.map(file => {
          const tests = visibleTests(file);
          if (tests.length === 0) return null;
          const isOpen = expanded.has(file.file);
          const fileStats = file.tests.reduce((acc, t) => { acc[t.status] = (acc[t.status] || 0) + 1; return acc; }, {});
          return (
            <div key={file.file} className="card">
              <div style={{ padding: "14px 16px", display: "grid", gridTemplateColumns: "auto 1fr auto auto", gap: 14, alignItems: "center", cursor: "pointer" }}
                   onClick={() => toggle(file.file)}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--surface-2)", border: "1px solid var(--border)", display: "grid", placeItems: "center", color: "var(--accent)" }}>
                  <Icon name={file.icon} size={18} />
                </div>
                <div style={{ minWidth: 0 }}>
                  <div className="mono" style={{ fontSize: 13, color: "var(--text)", marginBottom: 3 }}>{file.file}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-3)" }}>{file.group} · {file.tests.length} tests</div>
                </div>
                <div style={{ display: "flex", gap: 6 }}>
                  {fileStats.pass > 0 && <Pill kind="pass" dot={false}>{fileStats.pass} pass</Pill>}
                  {fileStats.flaky > 0 && <Pill kind="flaky" dot={false}>{fileStats.flaky} flaky</Pill>}
                  {fileStats.fail > 0 && <Pill kind="fail" dot={false}>{fileStats.fail} fail</Pill>}
                </div>
                <span style={{ color: "var(--text-3)", transform: isOpen ? "rotate(90deg)" : "none", transition: "transform .15s ease" }}>
                  <Icon name="chevron" size={14} />
                </span>
              </div>
              {isOpen && (
                <div style={{ borderTop: "1px solid var(--border)" }}>
                  {tests.map((t, i) => (
                    <div key={t.name}
                         style={{
                           display: "grid",
                           gridTemplateColumns: "16px 1fr auto auto",
                           gap: 14, alignItems: "center",
                           padding: "var(--row-pad) 16px var(--row-pad) 60px",
                           borderBottom: i < tests.length - 1 ? "1px solid var(--border)" : "none",
                           transition: "background .12s ease",
                           cursor: "pointer",
                         }}
                         onMouseEnter={(e) => e.currentTarget.style.background = "var(--surface-2)"}
                         onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}>
                      <span style={{
                        width: 16, height: 16, borderRadius: 4, display: "grid", placeItems: "center",
                        color: `var(--${t.status})`, background: `var(--${t.status}-2)`,
                      }}>
                        <Icon name={t.status === "pass" ? "check" : t.status === "fail" ? "x" : "bolt"} size={11} />
                      </span>
                      <div style={{ minWidth: 0 }}>
                        <div className="mono" style={{ fontSize: 12.5, color: "var(--text)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                          {t.name}
                        </div>
                        {t.error && (
                          <div className="mono" style={{ fontSize: 11.5, color: "var(--fail)", marginTop: 3 }}>{t.error}</div>
                        )}
                      </div>
                      <span className="mono" style={{ fontSize: 11.5, color: "var(--text-3)" }}>{t.duration.toFixed(1)}s</span>
                      <StatusPill status={t.status} />
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

window.AppiumView = AppiumView;
