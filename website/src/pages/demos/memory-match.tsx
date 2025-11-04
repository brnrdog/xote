import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function MemoryMatchDemo(): React.JSX.Element {
  return (
    <Layout
      title="Memory Match Demo"
      description="2-player memory matching game with 10 progressive levels and score tracking">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Memory Match Demo</h1>
            <p className="hero__subtitle">
              Play a 2-player memory matching game built entirely with Xote
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/match" title="Memory Match Demo" minHeight="800px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This Memory Match game demonstrates advanced reactive patterns:
            </p>
            <ul>
              <li><strong>Turn-Based Gameplay</strong> - 2-player competition with automatic turn switching</li>
              <li><strong>Progressive Difficulty</strong> - 10 levels from 4 cards to 30 cards</li>
              <li><strong>Score Tracking</strong> - Real-time score updates for both players</li>
              <li><strong>Timed Animations</strong> - Delayed card flipping for better UX</li>
              <li><strong>Game State Management</strong> - Playing, level complete, and game won states</li>
              <li><strong>Responsive Layout</strong> - Adaptive grid system based on card count</li>
            </ul>
            <p>
              The game uses signals to manage all game state including cards, scores, and current player.
              Computed attributes handle dynamic styling based on card states. The card matching logic
              uses setTimeout for animations while maintaining reactive updates throughout the game.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>Game Features</h2>
            <ul>
              <li><strong>30 Unique Symbols</strong> - Beautiful emoji icons for cards</li>
              <li><strong>Smart Shuffling</strong> - Cards are randomized at the start of each level</li>
              <li><strong>Match Detection</strong> - Automatic matching with visual feedback</li>
              <li><strong>Win Conditions</strong> - Complete all 10 levels to win the game</li>
              <li><strong>Player Indicators</strong> - Clear visual feedback for whose turn it is</li>
            </ul>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/MatchGame.res">
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
