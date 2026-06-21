import { Computed, Effect, Html, Signal, View } from "xote/client";
import { Router } from "xote/router";
import "./styles.css";

type Todo = {
  id: string;
  title: string;
  done: boolean;
};

type Filter = "all" | "active" | "done";

const todos = Signal.make<Todo[]>(
  [
    { id: "task-plan", title: "Sketch the UI state", done: true },
    {
      id: "task-signals",
      title: "Wire signals and computed views",
      done: false,
    },
    { id: "task-polish", title: "Add the finishing interactions", done: false },
  ],
  "todos",
);
const draft = Signal.make("", "draft");
const filter = Signal.make<Filter>("all", "filter");

Router.init();

const currentPath = Computed.make(
  () => Signal.get(Router.location()).pathname,
  "currentPath",
);

const visibleTodos = Computed.make(() => {
  const currentFilter = Signal.get(filter);
  const currentTodos = Signal.get(todos);

  if (currentFilter === "active") {
    return currentTodos.filter((todo) => !todo.done);
  }

  if (currentFilter === "done") {
    return currentTodos.filter((todo) => todo.done);
  }

  return currentTodos;
}, "visibleTodos");

const remainingCount = Computed.make(
  () => Signal.get(todos).filter((todo) => !todo.done).length,
  "remainingCount",
);

const completionLabel = Computed.make(() => {
  const total = Signal.get(todos).length;
  const remaining = Signal.get(remainingCount);
  const completed = total - remaining;

  if (total === 0) {
    return "No tasks yet";
  }

  return `${completed} of ${total} complete`;
}, "completionLabel");

Effect.run(() => {
  const path = Signal.get(currentPath);
  document.title =
    path === "/"
      ? `${Signal.get(remainingCount)} remaining - Xote TypeScript`
      : "Task detail - Xote TypeScript";
  return undefined;
}, "documentTitle");

const addTodo = () => {
  const title = Signal.peek(draft).trim();

  if (title === "") {
    return;
  }

  Signal.batch(() => {
    Signal.update(todos, (items) => [
      ...items,
      {
        id: `task-${Date.now()}`,
        title,
        done: false,
      },
    ]);
    Signal.set(draft, "");
  });
};

const toggleTodo = (id: string) => {
  Signal.update(todos, (items) =>
    items.map((todo) =>
      todo.id === id ? { ...todo, done: !todo.done } : todo,
    ),
  );
};

const removeTodo = (id: string) => {
  Signal.update(todos, (items) => items.filter((todo) => todo.id !== id));

  if (Signal.peek(currentPath) === `/tasks/${id}`) {
    Router.replace("/");
  }
};

const clearCompleted = () => {
  Signal.update(todos, (items) => items.filter((todo) => !todo.done));
};

const setDraftFromInput = (event: Event) => {
  Signal.set(draft, (event.currentTarget as HTMLInputElement).value);
};

const handleComposerKeydown = (event: Event) => {
  const keyboardEvent = event as KeyboardEvent;

  if (keyboardEvent.key === "Enter") {
    addTodo();
  }
};

const button = (label: string, onClick: () => void, className = "button") =>
  Html.button(
    [View.attr("type", "button"), View.attr("class", className)],
    [["click", onClick]],
    [View.text(label)],
  );

const filterButton = (target: Filter, label: string) =>
  Html.button(
    [
      View.attr("type", "button"),
      View.computedAttr("class", () =>
        Signal.get(filter) === target ? "filter is-active" : "filter",
      ),
      View.computedAttr("aria-pressed", () =>
        Signal.get(filter) === target ? "true" : "false",
      ),
    ],
    [["click", () => Signal.set(filter, target)]],
    [View.text(label)],
  );

const navLink = (to: string, label: string) =>
  Router.link(
    to,
    [
      View.computedAttr("class", () =>
        Signal.get(currentPath) === to ? "nav-link is-active" : "nav-link",
      ),
    ],
    [View.text(label)],
  );

const todoItem = (todo: Todo) =>
  Html.li(
    [
      View.attr("class", todo.done ? "todo is-done" : "todo"),
      View.attr("data-id", todo.id),
    ],
    [],
    [
      Html.button(
        [
          View.attr("type", "button"),
          View.attr("class", "toggle"),
          View.attr("aria-label", todo.done ? "Mark active" : "Mark complete"),
        ],
        [["click", () => toggleTodo(todo.id)]],
        [View.text(todo.done ? "Done" : "Todo")],
      ),
      Html.span(
        [View.attr("class", "todo-title")],
        [],
        [
          Router.link(
            `/tasks/${todo.id}`,
            [View.attr("class", "task-link")],
            [View.text(todo.title)],
          ),
        ],
      ),
      Html.button(
        [
          View.attr("type", "button"),
          View.attr("class", "remove"),
          View.attr("aria-label", `Remove ${todo.title}`),
        ],
        [["click", () => removeTodo(todo.id)]],
        [View.text("Remove")],
      ),
    ],
  );

const tasksPage = () =>
  View.fragment([
    Html.div(
      [View.attr("class", "panel composer")],
      [],
      [
        Html.input(
          [
            View.attr("type", "text"),
            View.attr("placeholder", "Add a task"),
            View.attr("aria-label", "New task"),
            View.signalAttr("value", draft),
          ],
          [
            ["input", setDraftFromInput],
            ["keydown", handleComposerKeydown],
          ],
        ),
        button("Add task", addTodo, "button primary"),
      ],
    ),
    Html.div(
      [View.attr("class", "toolbar")],
      [],
      [
        Html.div(
          [View.attr("class", "filters")],
          [],
          [
            filterButton("all", "All"),
            filterButton("active", "Active"),
            filterButton("done", "Done"),
          ],
        ),
        Html.div(
          [View.attr("class", "status")],
          [],
          [View.signalText(() => Signal.get(completionLabel))],
        ),
      ],
    ),
    Html.ul(
      [View.attr("class", "todo-list")],
      [],
      [
        View.eachWithKey(
          visibleTodos,
          (todo) => todo.id,
          (todo) => todoItem(todo),
        ),
      ],
    ),
    Html.div(
      [View.attr("class", "panel footer")],
      [],
      [
        Html.span(
          [],
          [],
          [
            View.signalText(() => {
              const count = Signal.get(remainingCount);
              return `${count} ${count === 1 ? "task" : "tasks"} remaining`;
            }),
          ],
        ),
        button("Clear completed", clearCompleted),
      ],
    ),
  ]);

const taskDetailPage = (id: string | undefined) =>
  View.signalFragment(
    Computed.make(() => {
      const task = Signal.get(todos).find((todo) => todo.id === id);

      if (!task) {
        return [
          Html.div(
            [View.attr("class", "detail-panel")],
            [],
            [
              Html.h2([], [], [View.text("Task not found")]),
              Html.p([], [], [
                View.text("The selected task is no longer in the list."),
              ]),
              Router.link("/", [View.attr("class", "button inline-link")], [
                View.text("Back to tasks"),
              ]),
            ],
          ),
        ];
      }

      return [
        Html.div(
          [View.attr("class", "detail-panel")],
          [],
          [
            Router.link("/", [View.attr("class", "back-link")], [
              View.text("Back to tasks"),
            ]),
            Html.h2([], [], [View.text(task.title)]),
            Html.p([], [], [
              View.text(
                task.done
                  ? "This task is complete."
                  : "This task is still active.",
              ),
            ]),
            Html.div(
              [View.attr("class", "detail-actions")],
              [],
              [
                button(
                  task.done ? "Mark active" : "Mark complete",
                  () => toggleTodo(task.id),
                  "button primary",
                ),
                button("Remove", () => removeTodo(task.id)),
              ],
            ),
          ],
        ),
      ];
    }, `taskDetail:${id ?? "missing"}`),
  );

const routes = Router.routes([
  { pattern: "/", render: () => tasksPage() },
  { pattern: "/tasks/:id", render: (params) => taskDetailPage(params.id) },
]);

const app = Html.div(
  [View.attr("class", "app-shell")],
  [],
  [
    Html.div(
      [View.attr("class", "hero")],
      [],
      [
        Html.h1([], [], [View.text("Tasks")]),
        Html.p(
          [],
          [],
          [
            View.text(
              "A small TypeScript frontend using Xote signals, computeds, effects, reactive attributes, keyed list rendering, and router-driven screens.",
            ),
          ],
        ),
      ],
    ),
    View.element(
      "nav",
      [View.attr("class", "app-nav"), View.attr("aria-label", "App")],
      [],
      [
        navLink("/", "Tasks"),
        Html.span(
          [View.attr("class", "path-readout")],
          [],
          [View.signalText(() => `Current route: ${Signal.get(currentPath)}`)],
        ),
      ],
    ),
    routes,
  ],
);

View.mountById(app, "app");
