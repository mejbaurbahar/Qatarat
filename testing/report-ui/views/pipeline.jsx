// CI/CD pipeline view — workflows + visualized pipeline
const PipelineView = () => {
  const { CI_WORKFLOWS } = window.QATARAT_DATA;

  return (
    <div className="grid" style={{ gap: 18 }}>
      <div>
        <h1 className="h1" style={{ fontSize: 22 }}>CI / CD pipeline</h1>
        <p className="lead" style={{ fontSize: 13 }}>GitHub Actions on free Ubuntu runners with Android emulator (API 33) and iOS simulator on macOS.</p>
      </div>

      {/* Pipeline diagram */}
      <div className="card">
        <div className="card-head"><h3>Pipeline</h3><span className="sub">push → build → test → publish</span></div>
        <div className="card-body">
          <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 0, alignItems: "stretch", position: "relative" }}>
            {[
              { label: "Source", icon: "branch", note: "Push to main", color: "oklch(70% 0.04 260)" },
              { label: "Build", icon: "bolt", note: "Flutter build apk", color: "oklch(74% 0.16 195)" },
              { label: "Maestro", icon: "flows", note: "16 flows · ~10m", color: "oklch(74% 0.18 155)" },
              { label: "Appium", icon: "appium", note: "22 deep tests · ~60m", color: "oklch(80% 0.16 75)" },
              { label: "Publish", icon: "download", note: "GitHub Pages", color: "oklch(75% 0.16 280)" },
            ].map((s, i, arr) => (
              <div key={s.label} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10, position: "relative" }}>
                {i < arr.length - 1 && (
                  <div style={{
                    position: "absolute", top: 28, left: "60%", right: "-40%", height: 2,
                    background: `linear-gradient(90deg, ${s.color} 0%, ${arr[i+1].color} 100%)`,
                    opacity: 0.4,
                  }} />
                )}
                <div style={{
                  width: 56, height: 56, borderRadius: 14,
                  background: `linear-gradient(180deg, color-mix(in oklch, ${s.color} 16%, var(--surface)), var(--surface))`,
                  border: `1px solid color-mix(in oklch, ${s.color} 32%, var(--border))`,
                  display: "grid", placeItems: "center", color: s.color,
                  boxShadow: `0 12px 24px -16px color-mix(in oklch, ${s.color} 50%, transparent)`,
                  position: "relative", zIndex: 1,
                }}>
                  <Icon name={s.icon} size={22} />
                </div>
                <div style={{ textAlign: "center" }}>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{s.label}</div>
                  <div className="mono" style={{ fontSize: 11, color: "var(--text-3)", marginTop: 2 }}>{s.note}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Workflows table */}
      <div className="card">
        <div className="card-head">
          <h3>Workflows</h3>
          <span className="sub">{CI_WORKFLOWS.length} pipelines configured</span>
        </div>
        <div className="card-body" style={{ padding: 0 }}>
          <table className="t">
            <thead>
              <tr>
                <th>Workflow</th>
                <th>Trigger</th>
                <th>Duration</th>
                <th>Last run</th>
                <th>Pass rate</th>
                <th style={{ textAlign: "right" }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {CI_WORKFLOWS.map(w => (
                <tr key={w.name}>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <div style={{
                        width: 30, height: 30, borderRadius: 8,
                        background: w.status === "pass" ? "var(--pass-2)" : w.status === "fail" ? "var(--fail-2)" : "var(--idle-2)",
                        color: w.status === "pass" ? "var(--pass)" : w.status === "fail" ? "var(--fail)" : "var(--idle)",
                        display: "grid", placeItems: "center",
                      }}>
                        <Icon name={w.status === "pass" ? "check" : w.status === "fail" ? "x" : "clock"} size={14} />
                      </div>
                      <div>
                        <div className="name">{w.name}</div>
                        <div className="meta">{w.coverage}</div>
                      </div>
                    </div>
                  </td>
                  <td className="mono" style={{ fontSize: 12, color: "var(--text-2)" }}>{w.trigger}</td>
                  <td className="mono" style={{ fontSize: 12, color: "var(--text-2)" }}>{w.duration}</td>
                  <td className="mono" style={{ fontSize: 12, color: "var(--text-3)" }}>{w.lastRun}</td>
                  <td style={{ minWidth: 160 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <div style={{ flex: 1, height: 5, background: "var(--surface-3)", borderRadius: 999, overflow: "hidden" }}>
                        <div style={{
                          width: `${w.passRate}%`, height: "100%",
                          background: w.passRate > 95 ? "var(--pass)" : w.passRate > 90 ? "var(--flaky)" : "var(--fail)",
                          transition: "width .6s ease",
                        }} />
                      </div>
                      <span className="mono" style={{ fontSize: 11.5, color: "var(--text-2)", minWidth: 40, textAlign: "right" }}>{w.passRate.toFixed(1)}%</span>
                    </div>
                    <div className="mono" style={{ fontSize: 10.5, color: "var(--text-3)", marginTop: 3 }}>{w.runs} runs</div>
                  </td>
                  <td style={{ textAlign: "right" }}><StatusPill status={w.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Tech stack */}
      <div className="card">
        <div className="card-head"><h3>Tech stack</h3><span className="sub">end-to-end</span></div>
        <div className="card-body">
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 12 }}>
            {[
              { layer: "App", tech: "Flutter / Dart", icon: "phone", c: "oklch(74% 0.16 195)" },
              { layer: "UI automation", tech: "Maestro 2.x", icon: "flows", c: "oklch(74% 0.18 155)" },
              { layer: "Deep tests", tech: "Appium 2.x + Flutter driver", icon: "appium", c: "oklch(80% 0.16 75)" },
              { layer: "Test language", tech: "Python 3 + pytest", icon: "bolt", c: "oklch(75% 0.14 230)" },
              { layer: "Reporting", tech: "Allure + GitHub Pages", icon: "overview", c: "oklch(75% 0.16 280)" },
              { layer: "CI / CD", tech: "GitHub Actions", icon: "pipeline", c: "oklch(70% 0.18 25)" },
            ].map(s => (
              <div key={s.layer} style={{ display: "flex", gap: 12, alignItems: "center", padding: 12, background: "var(--surface-2)", borderRadius: 10, border: "1px solid var(--border)" }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 9,
                  background: `color-mix(in oklch, ${s.c} 14%, transparent)`,
                  border: `1px solid color-mix(in oklch, ${s.c} 30%, transparent)`,
                  color: s.c, display: "grid", placeItems: "center",
                }}>
                  <Icon name={s.icon} size={16} />
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-3)", textTransform: "uppercase", letterSpacing: ".08em" }}>{s.layer}</div>
                  <div style={{ fontSize: 13, color: "var(--text)", marginTop: 1 }}>{s.tech}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

window.PipelineView = PipelineView;
