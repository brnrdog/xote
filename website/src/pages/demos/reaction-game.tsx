import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function ReactionGameDemo(): React.JSX.Element {
  return (
    <Layout
      title="Reaction Game Demo"
      description="Reflex testing game with timers, statistics, and computed averages">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Reaction Game Demo</h1>
            <p className="hero__subtitle">
              Test your reflexes with this interactive game featuring statistics and history
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/reaction" title="Reaction Game Demo" minHeight="700px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This reaction game demonstrates timing and state management:
            </p>
            <ul>
              <li><strong>Game State</strong> - Managing multiple game phases with signals</li>
              <li><strong>Timers</strong> - Using effects to track reaction times</li>
              <li><strong>Statistics</strong> - Computed averages and best times</li>
              <li><strong>History</strong> - Reactive lists showing attempt history</li>
              <li><strong>Conditional Rendering</strong> - Different UI for each game phase</li>
            </ul>
            <p>
              The game uses signals to track game state, reaction times, and attempt history.
              Computed values calculate statistics like average reaction time and best attempt.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/ReactionGame.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/components/overview">
                Learn About Components
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
