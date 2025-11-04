import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';

const demos = [
  {
    title: 'Counter',
    description: 'Simple reactive counter with signals and event handlers',
    path: '/demos/counter',
    route: '/counter',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/CounterApp.res',
  },
  {
    title: 'Todo List',
    description: 'Complete todo app with filters, computed values, and reactive lists',
    path: '/demos/todo',
    route: '/todo',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/TodoApp.res',
  },
  {
    title: 'Color Mixer',
    description: 'RGB color mixing with live preview, format conversions, and palette variations',
    path: '/demos/color-mixer',
    route: '/color',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/ColorMixerApp.res',
  },
  {
    title: 'Reaction Game',
    description: 'Reflex testing game with timers, statistics, and computed averages',
    path: '/demos/reaction-game',
    route: '/reaction',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/ReactionGame.res',
  },
  {
    title: 'Solitaire',
    description: 'Classic Klondike Solitaire with click-to-move gameplay and win detection',
    path: '/demos/solitaire',
    route: '/solitaire',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/SolitaireGame.res',
  },
  {
    title: 'Memory Match',
    description: '2-player memory matching game with 10 progressive levels and score tracking',
    path: '/demos/memory-match',
    route: '/match',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/MatchGame.res',
  },
  {
    title: 'Functional Bookstore',
    description: 'E-commerce app with routing, cart management, checkout flow, and absurd FP-themed books',
    path: '/demos/bookstore',
    route: '/bookstore',
    source: 'https://github.com/brnrdog/xote/blob/main/demos/BookstoreApp.res',
  },
];

function DemoCard({title, description, path, source}: {title: string; description: string; path: string; source: string}) {
  return (
    <div className="card margin-bottom--lg">
      <div className="card__header">
        <h3>{title}</h3>
      </div>
      <div className="card__body">
        <p>{description}</p>
      </div>
      <div className="card__footer">
        <div style={{display: 'flex', gap: '0.5rem'}}>
          <Link className="button button--primary" to={path}>
            Try Demo
          </Link>
          <Link className="button button--secondary" to={source}>
            View Source
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function Demos(): React.JSX.Element {
  return (
    <Layout
      title="Demos"
      description="Interactive examples and demos for Xote">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Xote Demos</h1>
            <p className="hero__subtitle">
              Explore interactive examples showcasing Xote's capabilities
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div className="alert alert--info">
              <h4>Running Demos Locally</h4>
              <p>To run these demos on your machine:</p>
              <ol>
                <li>Clone the repository: <code>git clone https://github.com/brnrdog/xote.git</code></li>
                <li>Install dependencies: <code>npm install</code></li>
                <li>Start ReScript compiler: <code>npm run res:dev</code> (in one terminal)</li>
                <li>Start dev server: <code>npm run dev</code> (in another terminal)</li>
                <li>Open <code>http://localhost:5173</code> in your browser</li>
              </ol>
            </div>
          </div>
        </div>

        <div className="row margin-top--lg">
          {demos.map((demo, idx) => (
            <div key={idx} className="col col--4">
              <DemoCard {...demo} />
            </div>
          ))}
        </div>

        <div className="row margin-top--xl">
          <div className="col">
            <div className="text--center">
              <h2>Want to contribute?</h2>
              <p>
                Have an idea for a demo? Check out the{' '}
                <Link to="https://github.com/brnrdog/xote">GitHub repository</Link> to
                contribute your own examples!
              </p>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
