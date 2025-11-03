import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function TodoDemo(): React.JSX.Element {
  return (
    <Layout
      title="Todo List Demo"
      description="Complete todo app with filters, computed values, and reactive lists">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Todo List Demo</h1>
            <p className="hero__subtitle">
              A full-featured todo application showcasing computed values and reactive lists
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/todo" title="Todo List Demo" minHeight="700px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This todo app demonstrates more advanced Xote features:
            </p>
            <ul>
              <li><strong>Signals</strong> - Managing todo items and filter state</li>
              <li><strong>Computed Values</strong> - Automatically filtering and counting todos</li>
              <li><strong>Reactive Lists</strong> - Rendering arrays that update when data changes</li>
              <li><strong>Event Handlers</strong> - Adding, completing, and deleting todos</li>
              <li><strong>Batching</strong> - Grouping multiple updates for efficiency</li>
            </ul>
            <p>
              The todo list uses computed values to derive filtered lists and statistics from
              the base todo array. When you add, complete, or filter todos, only the necessary
              parts of the UI update.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/TodoApp.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/core-concepts/computed">
                Learn About Computed Values
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
