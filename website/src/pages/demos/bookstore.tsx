import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function BookstoreDemo(): React.JSX.Element {
  return (
    <Layout
      title="Functional Bookstore Demo"
      description="E-commerce app with routing, cart management, checkout flow, and absurd FP-themed books">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Functional Bookstore Demo</h1>
            <p className="hero__subtitle">
              A complete e-commerce experience featuring absurd functional programming themed books
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div className="alert alert--info margin-bottom--md">
              <strong>💡 Best Experience:</strong> For the full routing experience with browser history integration,{' '}
              <Link to="/demos/bookstore.html" target="_blank">
                open the demo in a new tab →
              </Link>
            </div>
            <DemoFrame route="/bookstore" title="Functional Bookstore Demo" minHeight="800px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This bookstore demonstrates a complete e-commerce flow with Xote's routing capabilities:
            </p>
            <ul>
              <li><strong>Multi-Route Navigation</strong> - Four routes: catalog, cart, checkout, and order confirmation</li>
              <li><strong>Router Integration</strong> - Uses Xote Router for SPA navigation with clean URLs</li>
              <li><strong>Shopping Cart</strong> - Add/remove items, adjust quantities, real-time total calculation</li>
              <li><strong>Checkout Flow</strong> - Multi-step process with form handling and validation</li>
              <li><strong>State Management</strong> - Cart persists across navigation, reactive updates throughout</li>
              <li><strong>Active Link Highlighting</strong> - Navigation shows current route</li>
            </ul>
            <p>
              The app showcases Xote's routing system working seamlessly with signals for state management.
              All navigation is client-side with no page reloads, and the browser's back/forward buttons work correctly.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>Routing Features Demonstrated</h2>
            <ul>
              <li><strong>Route Definition</strong> - Declarative routing with pattern matching</li>
              <li><strong>Router.link</strong> - SPA navigation without page reloads</li>
              <li><strong>Router.routes</strong> - Rendering components based on URL patterns</li>
              <li><strong>Router.location</strong> - Reactive signal tracking current route</li>
              <li><strong>Router.push</strong> - Programmatic navigation (checkout → order confirmation)</li>
              <li><strong>Clean URLs</strong> - Routes: /, /catalog, /about, /cart, /checkout, /order-confirmed</li>
            </ul>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>The Books</h2>
            <p>
              Enjoy browsing our curated collection of 12 fictional books with absurd titles like:
            </p>
            <ul>
              <li><em>"The Reactive Manifesto: A Monad's Journey"</em> by Dr. Lambda Calculus</li>
              <li><em>"Currying for Beginners: One Argument at a Time"</em> by Haskell B. Curry Jr.</li>
              <li><em>"Recursion: See Recursion"</em> by Stack O. Verflow</li>
              <li><em>"The Side Effect Strikes Back"</em> by I. O. Monad</li>
            </ul>
            <p>
              All priced in our fictional currency: Functors (Ƒ) 💰
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/BookstoreApp.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/router/overview">
                Router Documentation
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
