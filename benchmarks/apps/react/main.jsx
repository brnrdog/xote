import "../../shared/bench.css";
import { useCallback, useState } from "react";
import { createRoot } from "react-dom/client";
import { buildData } from "../../shared/data.js";

/* Idiomatic React: immutable row array held in state, rows re-rendered
 * through the reconciler on every change. */

function Row({ row, selected, onSelect, onRemove }) {
  return (
    <tr className={selected ? "danger" : ""}>
      <td className="col-md-1">{row.id}</td>
      <td className="col-md-4">
        <a className="lbl" onClick={() => onSelect(row.id)}>
          {row.label}
        </a>
      </td>
      <td className="col-md-1">
        <a className="remove" onClick={() => onRemove(row.id)}>
          <span className="glyphicon glyphicon-remove" aria-hidden="true" />
        </a>
      </td>
      <td className="col-md-6" />
    </tr>
  );
}

function App() {
  const [rows, setRows] = useState([]);
  const [selected, setSelected] = useState(0);

  const run = useCallback(() => setRows(buildData(1000)), []);
  const runLots = useCallback(() => setRows(buildData(10000)), []);
  const add = useCallback(() => setRows((rs) => rs.concat(buildData(1000))), []);
  const clear = useCallback(() => setRows([]), []);

  const update = useCallback(
    () =>
      setRows((rs) => {
        const next = rs.slice();
        for (let i = 0; i < next.length; i += 10) {
          next[i] = { id: next[i].id, label: next[i].label + " !!!" };
        }
        return next;
      }),
    [],
  );

  const swapRows = useCallback(
    () =>
      setRows((rs) => {
        if (rs.length <= 998) return rs;
        const next = rs.slice();
        const tmp = next[1];
        next[1] = next[998];
        next[998] = tmp;
        return next;
      }),
    [],
  );

  const select = useCallback((id) => setSelected(id), []);
  const remove = useCallback(
    (id) => setRows((rs) => rs.filter((r) => r.id !== id)),
    [],
  );

  return (
    <div className="container">
      <div className="jumbotron">
        <h1>React</h1>
        <div className="actions">
          <button id="run" onClick={run}>Create 1,000 rows</button>
          <button id="runlots" onClick={runLots}>Create 10,000 rows</button>
          <button id="add" onClick={add}>Append 1,000 rows</button>
          <button id="update" onClick={update}>Update every 10th row</button>
          <button id="clear" onClick={clear}>Clear</button>
          <button id="swaprows" onClick={swapRows}>Swap Rows</button>
        </div>
      </div>
      <table id="main-table">
        <tbody id="tbody">
          {rows.map((row) => (
            <Row
              key={row.id}
              row={row}
              selected={selected === row.id}
              onSelect={select}
              onRemove={remove}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
/* Startup marker read by the benchmark driver. */
window.__BENCH_READY_AT__ = performance.now();
window.__BENCH_READY__ = true;
