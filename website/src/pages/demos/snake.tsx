import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function SnakeDemo(): React.JSX.Element {
  return (
    <Layout
      title="Snake Game"
      description="Classic Snake game with 10 progressive levels and increasing difficulty">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>🐍 Snake Game</h1>
            <p className="hero__subtitle">
              Classic Snake game with 10 challenging levels, obstacles, and increasing difficulty
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/snake" title="Snake Game" minHeight="700px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This demo showcases advanced Xote features through a complete game implementation:
            </p>
            <ul>
              <li><strong>Game Loop</strong> - Recursive setTimeout pattern with level-specific speeds</li>
              <li><strong>Complex State</strong> - Multiple signals managing snake, food, obstacles, and game state</li>
              <li><strong>Collision Detection</strong> - Spatial logic for walls, obstacles, and self-collision</li>
              <li><strong>Keyboard Input</strong> - Effect-based event listeners with proper cleanup</li>
              <li><strong>Progressive Levels</strong> - 10 levels with increasing speed and obstacle complexity</li>
              <li><strong>Reactive Rendering</strong> - Dynamic grid rendering with Component.list</li>
            </ul>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>Game Features</h2>
            <div className="row">
              <div className="col col--6">
                <h3>Controls</h3>
                <ul>
                  <li>Arrow Keys or WASD to move</li>
                  <li>Space to pause/resume</li>
                  <li>Context-aware buttons for game actions</li>
                </ul>
              </div>
              <div className="col col--6">
                <h3>Progression</h3>
                <ul>
                  <li>Levels 1-2: Learn the basics (200-180ms)</li>
                  <li>Levels 3-4: Obstacles introduced (160-140ms)</li>
                  <li>Levels 5-6: Complex patterns (120-110ms)</li>
                  <li>Levels 7-8: Advanced challenges (100-90ms)</li>
                  <li>Levels 9-10: Expert mode (80-70ms)</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>Implementation Highlights</h2>
            <p>
              The Snake game demonstrates several important patterns:
            </p>
            <ul>
              <li><strong>Reactive Game Loop</strong> - Uses recursive setTimeout with signal-based state updates</li>
              <li><strong>Effect Cleanup</strong> - Keyboard listeners properly registered and cleaned up</li>
              <li><strong>Computed Configuration</strong> - Level settings computed reactively from level number</li>
              <li><strong>Component Composition</strong> - GameGrid, GameInfo, GameControls, GameStatus components</li>
              <li><strong>State Machine</strong> - Game states: Paused, Playing, GameOver, LevelComplete</li>
              <li><strong>Dynamic Styling</strong> - Reactive style attributes for food position updates</li>
            </ul>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/SnakeGame.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/core-concepts/effects">
                Learn About Effects
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
