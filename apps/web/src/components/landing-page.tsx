"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";
import gsap from "gsap";

const stepItems = [
  ["01", "Create your profile", "Tell your story in your language"],
  ["02", "List your crafts", "Add details with simple tools"],
  ["03", "Get on marketplaces", "Reach buyers across online platforms"],
  ["04", "Track & grow", "See insights and grow your business"],
];

const stories = [
  { name: "Ramesh Kumar", craft: "Wood Craft · Karnataka", quote: "I never thought my work could reach so many people online. KalaSetu made it possible.", image: "/assets/heroes/KS-Hero.png", position: "13% 17%" },
  { name: "Meena Devi", craft: "Textile · Maharashtra", quote: "Listing my products was simple, and now I get enquiries from across the country.", image: "/assets/Landing-Support-2.png", position: "78% 38%" },
  { name: "Abdul Rahman", craft: "Metal Craft · Uttar Pradesh", quote: "With KalaSetu, I can focus on my craft while it takes care of the rest.", image: "/assets/heroes/KS-Hero.png", position: "76% 16%" },
];

export function LandingPage() {
  const rootRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const context = gsap.context(() => {
      gsap.from(".landing-reveal", {
        y: 22,
        opacity: 0,
        filter: "blur(8px)",
        duration: 0.9,
        stagger: 0.07,
        ease: "power3.out",
      });
      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
      const landscape = root.querySelector<HTMLElement>(".hero-landscape img");
      const collage = root.querySelector<HTMLElement>(".hero-collage img");
      if (!landscape || !collage) return;
      const moveLandscape = gsap.quickTo(landscape, "x", { duration: 1.1, ease: "power3.out" });
      const moveCollage = gsap.quickTo(collage, "y", { duration: 1.1, ease: "power3.out" });
      const onPointerMove = (event: PointerEvent) => {
        const bounds = root.getBoundingClientRect();
        const x = (event.clientX - bounds.left) / bounds.width - 0.5;
        const y = (event.clientY - bounds.top) / bounds.height - 0.5;
        moveLandscape(x * 9);
        moveCollage(y * -7);
      };
      root.addEventListener("pointermove", onPointerMove);
      gsap.to(collage, { y: -4, duration: 7, repeat: -1, yoyo: true, ease: "sine.inOut" });
      return () => root.removeEventListener("pointermove", onPointerMove);
    }, root);
    return () => context.revert();
  }, []);

  return (
    <main ref={rootRef}>
      <section className="hero-reference" aria-labelledby="hero-title">
        <div className="hero-reference-bg" aria-hidden="true" />
        <div className="hero-landscape" aria-hidden="true"><Image src="/assets/heroes/KS-Hero-2.png" alt="" width={2162} height={727} priority /></div>
        <div className="hero-collage" aria-hidden="true"><Image src="/assets/heroes/KS-Hero-transparent.png" alt="" width={1374} height={1145} priority /></div>
        <div className="hero-reference-copy">
          <span className="hero-eyebrow landing-reveal">Real people. Real progress.</span>
          <h1 id="hero-title" className="landing-reveal"><span>Empowering</span><span>Artisans.</span><span>Enabling Futures.</span></h1>
          <p className="landing-reveal">KalaSetu helps you showcase your work, get listed on leading platforms, and grow your craft business with a strong support system.</p>
          <Link className="button-primary landing-reveal" href="/language">Enter as an Artisan <span aria-hidden="true">→</span></Link>
        </div>
        <div className="hero-reference-words landing-reveal" aria-hidden="true">
          <span>People</span><span>Craft</span><span>Technology</span><span>Markets</span><span>Opportunity</span>
          <i />
          <span>A kinder</span><span>A brighter</span><span>tomorrow</span>
        </div>
      </section>

      <section className="partner-section" id="how-it-works" aria-labelledby="partner-title">
        <div className="partner-copy">
          <span className="section-mark">More than a platform</span>
          <h2 id="partner-title">Your Partner<br />at Every Step</h2>
          <p>From listing your products to reaching new customers, KalaSetu gives you the tools, guidance, and support to grow — so you can focus on what you do best.</p>
          <Link className="button-secondary" href="/capture">See How It Works <span aria-hidden="true">→</span></Link>
        </div>
        <div className="step-track">
          {stepItems.map(([number, title, copy]) => (
            <article className="step-item" key={number}>
              <div className="step-icon" aria-hidden="true"><span>{number}</span></div>
              <strong>{title}</strong>
              <p>{copy}</p>
            </article>
          ))}
        </div>
        <div className="hand-script" aria-hidden="true">Same<br />Hands.<br />New<br />Horizons.</div>
        <div className="woven-ornament partner-ornament" aria-hidden="true"><span /><span /><span /><span /><span /><span /><span /><span /><span /></div>
      </section>

      <section className="feature-section" id="for-artisans" aria-labelledby="feature-title">
        <div className="feature-image"><Image src="/assets/Landing-Support-2.png" alt="An artisan working with textile tools" width={2172} height={724} /></div>
        <div className="feature-copy">
          <span className="section-mark">Tradition meets technology</span>
          <h2 id="feature-title">Built for Artisans.<br />Designed for Growth.</h2>
          <p>A simple, supportive platform that connects your craft to new markets, while keeping your identity, your story, and your community at the center.</p>
          <Link className="button-secondary" href="/shop">Explore Features <span aria-hidden="true">→</span></Link>
        </div>
        <div className="dashboard-mockup" aria-label="Illustrative craft growth dashboard">
          <div className="dashboard-sidebar"><span className="dashboard-dot" /><span /><span /><span /><span /></div>
          <div className="dashboard-content">
            <div className="dashboard-topline"><span>Your Craft<br /><b>Your Growth</b></span><i>•••</i></div>
            <div className="dashboard-chart"><span style={{ height: "36%" }} /><span style={{ height: "58%" }} /><span style={{ height: "45%" }} /><span style={{ height: "78%" }} /><span style={{ height: "68%" }} /><span style={{ height: "92%" }} /></div>
            <div className="dashboard-stat"><small>More opportunities this month</small><strong>+62%</strong></div>
          </div>
          <div className="dashboard-badge"><span>Listed on</span><b>5+ Platforms</b></div>
        </div>
        <div className="feature-side-words" aria-hidden="true">Tools<br />Guidance<br />Markets<br />Community<br />A Brighter<br />Tomorrow</div>
      </section>

      <section className="stories-section" aria-labelledby="stories-title">
        <div className="stories-intro">
          <span className="section-mark">Real stories. Real impact.</span>
          <h2 id="stories-title">Artisans Growing<br />Brighter Tomorrows</h2>
          <p>Meet the artisans who are reaching new markets, more customers, and greater opportunities with KalaSetu.</p>
          <Link className="button-primary" href="/insights">See Success Stories <span aria-hidden="true">→</span></Link>
        </div>
        <div className="stories-grid">
          {stories.map((story) => (
            <article className="story-card" key={story.name}>
              <div className="story-card-image"><Image src={story.image} alt="" width={600} height={420} style={{ objectPosition: story.position }} /></div>
              <div className="story-card-copy"><strong>{story.name}</strong><span>{story.craft}</span><p>“{story.quote}”</p></div>
            </article>
          ))}
          <Link className="many-crafts" href="/market">Many<br />Crafts.<br />One<br />Stronger<br />India. <span aria-hidden="true">→</span></Link>
        </div>
        <div className="woven-ornament stories-ornament" aria-hidden="true"><span /><span /><span /><span /><span /><span /><span /><span /><span /></div>
      </section>

      <section className="impact-section" aria-labelledby="impact-title">
        <div className="impact-copy">
          <span className="section-mark">A more inclusive tomorrow</span>
          <h2 id="impact-title">Stronger Communities.<br />Greater Opportunities.</h2>
          <p>When artisans grow, communities thrive. KalaSetu is building a more equitable, connected, and inclusive future for Indian crafts.</p>
          <Link className="button-primary" href="/insights">Our Impact <span aria-hidden="true">→</span></Link>
        </div>
        <div className="impact-stats">
          <span className="impact-note">Illustrative demo signals</span>
          <div><strong>2500+</strong><span>Artisans and counting</span></div>
          <div><strong>10+</strong><span>Marketplaces integrated</span></div>
          <div><strong>6</strong><span>Languages supported</span></div>
          <div><strong>1</strong><span>Stronger artisan community</span></div>
          <blockquote>“Craft is not just what we make, but the opportunities it creates.”</blockquote>
        </div>
        <div className="woven-ornament impact-ornament" aria-hidden="true"><span /><span /><span /><span /><span /><span /><span /><span /><span /></div>
      </section>

      <section className="join-section" aria-labelledby="join-title">
        <Image src="/assets/Landing-Support.png" alt="" width={2048} height={768} />
        <div className="join-copy">
          <span className="section-mark">Ready to take your craft further?</span>
          <h2 id="join-title">Try the artisan workspace</h2>
          <p>Start with one product. KalaSetu helps you capture, describe, price, and share it with care.</p>
          <Link className="button-secondary" href="/language">Enter as an Artisan <span aria-hidden="true">→</span></Link>
        </div>
        <div className="join-points"><span>Simple onboarding</span><span>Real support</span><span>Bigger opportunities</span></div>
      </section>

      <footer className="landing-footer">
        <div className="footer-brand"><Image src="/assets/brand/logo-transparent.png" alt="KalaSetu" width={1141} height={535} /><span>A kinder, a brighter tomorrow.</span><Link className="footer-cta" href="/language">Enter as Artisan <span aria-hidden="true">→</span></Link></div>
        <div><strong>Explore</strong><Link href="/#how-it-works">How it works</Link><Link href="/insights">Success stories</Link><Link href="/market">Resources</Link><Link href="/about">About</Link></div>
        <div><strong>Support</strong><Link href="/settings">Help center</Link><Link href="/market">Contact</Link><Link href="/insights">Community</Link><Link href="/settings">Feedback</Link></div>
        <div><strong>Legal</strong><Link href="/settings">Privacy policy</Link><Link href="/settings">Terms of service</Link><Link href="/settings">Accessibility</Link></div>
        <div className="footer-social"><strong>Stay connected</strong><span className="footer-social-links"><a href="#">YouTube</a><a href="#">Instagram</a><a href="#">LinkedIn</a><a href="#">X</a></span><span>English⌄</span></div>
        <small>© 2026 KalaSetu. All rights reserved.</small>
      </footer>
    </main>
  );
}
