import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function SolitaireDemo(): React.JSX.Element {
  return (
    <Layout
      title="Solitaire Demo"
      description="Classic Klondike Solitaire with click-to-move gameplay and win detection">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Solitaire Demo</h1>
            <p className="hero__subtitle">
              Play classic Klondike Solitaire built entirely with Xote
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/solitaire" title="Solitaire Demo" minHeight="900px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This Solitaire implementation demonstrates complex state management:
            </p>
            <ul>
              <li><strong>Game State</strong> - Managing deck, tableau, foundations, and waste pile</li>
              <li><strong>Complex Logic</strong> - Valid move checking and game rules</li>
              <li><strong>Dynamic Rendering</strong> - Rendering cards with conditional styling</li>
              <li><strong>Event Handling</strong> - Click-to-move card interactions</li>
              <li><strong>Win Detection</strong> - Computed value checking for game completion</li>
            </ul>
            <p>
              The game uses signals to manage all game state including card positions and visibility.
              Computed values check for valid moves and win conditions. The entire game logic is
              reactive - no manual DOM updates needed.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/SolitaireGame.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs">
                Read Documentation
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
