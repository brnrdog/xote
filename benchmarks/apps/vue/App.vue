<script setup>
import { shallowRef, triggerRef } from "vue";
import { buildData } from "../../shared/data.js";

/* Idiomatic Vue 3 for large lists: a shallowRef array (no per-row proxy
 * allocation) with explicit triggerRef after in-place mutation. */

const rows = shallowRef([]);
const selected = shallowRef(0);

const run = () => (rows.value = buildData(1000));
const runLots = () => (rows.value = buildData(10000));
const add = () => (rows.value = rows.value.concat(buildData(1000)));
const clear = () => (rows.value = []);

const update = () => {
  const rs = rows.value;
  for (let i = 0; i < rs.length; i += 10) {
    rs[i] = { id: rs[i].id, label: rs[i].label + " !!!" };
  }
  triggerRef(rows);
};

const swapRows = () => {
  const rs = rows.value;
  if (rs.length <= 998) return;
  const tmp = rs[1];
  rs[1] = rs[998];
  rs[998] = tmp;
  triggerRef(rows);
};

const select = (id) => (selected.value = id);
const remove = (id) => (rows.value = rows.value.filter((r) => r.id !== id));
</script>

<template>
  <div class="container">
    <div class="jumbotron">
      <h1>Vue</h1>
      <div class="actions">
        <button id="run" @click="run">Create 1,000 rows</button>
        <button id="runlots" @click="runLots">Create 10,000 rows</button>
        <button id="add" @click="add">Append 1,000 rows</button>
        <button id="update" @click="update">Update every 10th row</button>
        <button id="clear" @click="clear">Clear</button>
        <button id="swaprows" @click="swapRows">Swap Rows</button>
      </div>
    </div>
    <table id="main-table">
      <tbody id="tbody">
        <tr v-for="row in rows" :key="row.id" :class="selected === row.id ? 'danger' : ''">
          <td class="col-md-1">{{ row.id }}</td>
          <td class="col-md-4">
            <a class="lbl" @click="select(row.id)">{{ row.label }}</a>
          </td>
          <td class="col-md-1">
            <a class="remove" @click="remove(row.id)">
              <span class="glyphicon glyphicon-remove" aria-hidden="true" />
            </a>
          </td>
          <td class="col-md-6" />
        </tr>
      </tbody>
    </table>
  </div>
</template>
