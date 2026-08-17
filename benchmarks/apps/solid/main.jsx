import "../../shared/bench.css";
import { batch, createSignal, For } from "solid-js";
import { render } from "solid-js/web";
import { buildData } from "../../shared/data.js";

/* Idiomatic SolidJS: the list is one signal, each row's label is its own
 * signal so a label change writes a single text node. */

function makeRows(count) {
  return buildData(count).map((row) => {
    const [label, setLabel] = createSignal(row.label);
    return { id: row.id, label, setLabel };
  });
}

function App() {
  const [rows, setRows] = createSignal([]);
  const [selected, setSelected] = createSignal(0);

  const update = () => {
    const rs = rows();
    batch(() => {
      for (let i = 0; i < rs.length; i += 10) {
        rs[i].setLabel((l) => l + " !!!");
      }
    });
  };

  const swapRows = () => {
    const rs = rows();
    if (rs.length <= 998) return;
    const next = rs.slice();
    const tmp = next[1];
    next[1] = next[998];
    next[998] = tmp;
    setRows(next);
  };

  const remove = (id) => setRows((rs) => rs.filter((r) => r.id !== id));

  return (
    <div class="container">
      <div class="jumbotron">
        <h1>Solid</h1>
        <div class="actions">
          <button id="run" onClick={() => setRows(makeRows(1000))}>Create 1,000 rows</button>
          <button id="runlots" onClick={() => setRows(makeRows(10000))}>Create 10,000 rows</button>
          <button id="add" onClick={() => setRows((rs) => rs.concat(makeRows(1000)))}>Append 1,000 rows</button>
          <button id="update" onClick={update}>Update every 10th row</button>
          <button id="clear" onClick={() => setRows([])}>Clear</button>
          <button id="swaprows" onClick={swapRows}>Swap Rows</button>
        </div>
      </div>
      <table id="main-table">
        <tbody id="tbody">
          <For each={rows()}>
            {(row) => (
              <tr class={selected() === row.id ? "danger" : ""}>
                <td class="col-md-1">{row.id}</td>
                <td class="col-md-4">
                  <a class="lbl" onClick={() => setSelected(row.id)}>{row.label()}</a>
                </td>
                <td class="col-md-1">
                  <a class="remove" onClick={() => remove(row.id)}>
                    <span class="glyphicon glyphicon-remove" aria-hidden="true" />
                  </a>
                </td>
                <td class="col-md-6" />
              </tr>
            )}
          </For>
        </tbody>
      </table>
    </div>
  );
}

render(() => <App />, document.getElementById("root"));
/* Startup marker read by the benchmark driver. */
window.__BENCH_READY_AT__ = performance.now();
window.__BENCH_READY__ = true;
