/**
 * A pool of views, so a list that churns rows stops allocating.
 *
 * `destroy` is the natural place to return a view: the protocol guarantees the
 * id will never be referenced again, which is exactly the guarantee a pool
 * needs. `create` is the natural place to take one back out. Nothing in the
 * command stream changes; the host simply stops asking the platform for a fresh
 * object it already has.
 *
 * The policy is small and there are three decisions in it worth stating.
 *
 * **Pools are keyed by kind.** A `UILabel` is not a `UIView` and cannot stand
 * in for one. The kind is whatever the host uses to decide what to allocate,
 * which on iOS is the class and here is the node type.
 *
 * **Each pool is bounded.** A screen that destroys five thousand rows must not
 * hold five thousand views alive waiting for a sixth thousand that never comes.
 * The bound is per kind, and the excess is dropped rather than queued.
 *
 * **A view is reset on release, not on acquire.** Releasing is what happens on
 * a `destroy`, which is already a teardown; acquiring happens on the path that
 * is trying to be fast. It also means a pooled view is never sitting on a
 * reference — a text, an image, a delegate — that outlives the node that put it
 * there, which is the leak this would otherwise introduce.
 */

export const DEFAULT_LIMIT = 64;

export class ViewPool {
  /**
   * @param {{limit?: number, reset?: (kind: string, view: unknown) => void}} [options]
   */
  constructor({ limit = DEFAULT_LIMIT, reset } = {}) {
    this.limit = limit;
    this.reset = reset ?? null;
    /** @type {Map<string, unknown[]>} */
    this.free = new Map();
    this.created = 0;
    this.reused = 0;
    this.dropped = 0;
  }

  /**
   * A view of `kind`, from the pool if there is one and from `make` if not.
   * @param {string} kind
   * @param {() => unknown} make
   */
  acquire(kind, make) {
    const available = this.free.get(kind);
    if (available !== undefined && available.length > 0) {
      this.reused += 1;
      return available.pop();
    }
    this.created += 1;
    return make();
  }

  /**
   * Hand a view back. Returns whether it was kept — a caller that needs to
   * release platform resources on the ones that are not can act on that.
   * @param {string} kind
   */
  release(kind, view) {
    if (view === undefined || view === null) return false;
    let available = this.free.get(kind);
    if (available === undefined) {
      available = [];
      this.free.set(kind, available);
    }
    if (available.length >= this.limit) {
      this.dropped += 1;
      return false;
    }
    // Reset before it goes in, so nothing in the pool holds a reference to the
    // screen it came from.
    if (this.reset !== null) this.reset(kind, view);
    available.push(view);
    return true;
  }

  /** How many views are parked, in total and by kind. */
  get pooled() {
    let total = 0;
    for (const available of this.free.values()) total += available.length;
    return total;
  }

  stats() {
    const byKind = {};
    for (const [kind, available] of this.free) byKind[kind] = available.length;
    return {
      created: this.created,
      reused: this.reused,
      dropped: this.dropped,
      pooled: this.pooled,
      byKind,
    };
  }

  clear() {
    this.free.clear();
  }
}
