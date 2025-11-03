import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function CounterDemo(): React.JSX.Element {
  return (
    <Layout
      title="Counter Demo"
      description="Simple reactive counter with signals and event handlers">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Counter Demo</h1>
            <p className="hero__subtitle">
              A simple counter demonstrating reactive signals and event handlers
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/counter" title="Counter Demo" minHeight="400px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This demo showcases the basic building blocks of Xote:
            </p>
            <ul>
              <li><strong>Signals</strong> - Reactive state that automatically notifies dependents when changed</li>
              <li><strong>Event Handlers</strong> - Functions that respond to user interactions</li>
              <li><strong>Reactive Text</strong> - Text that updates automatically when signals change</li>
            </ul>
            <p>
              The counter uses a single signal to track the count value. When you click the buttons,
              event handlers update the signal, and the displayed count updates automatically.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/CounterApp.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/core-concepts/signals">
                Learn About Signals
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
