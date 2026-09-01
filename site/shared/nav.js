/* (c) 2026-* Frederick Bloom — Hanaden — nav.js */
/* DRY component system: footer injection, sidebar, mermaid, particles */
(function () {
  'use strict';

  // --- Path helpers ---
  // Compute site root from nav.js script src path
  // Script is always at shared/nav.js relative to site root
  var scriptTags = document.querySelectorAll('script[src*="nav.js"]');
  var siteRoot = '';
  if (scriptTags.length > 0) {
    var src = scriptTags[0].getAttribute('src');
    // Remove 'shared/nav.js' to get the relative path to site root
    siteRoot = src.replace('shared/nav.js', '').replace(/\/+$/, '');
    if (siteRoot) siteRoot += '/';
  }

  // --- Detect which subsite we're in ---
  var path = window.location.pathname;
  var inBusiness = path.indexOf('/business/') !== -1;
  var inTechnical = path.indexOf('/technical/') !== -1;
  var isHub = !inBusiness && !inTechnical;

  // ==========================================================================
  // DRY FOOTER — injected on every page
  // ==========================================================================
  function injectFooter() {
    var existing = document.querySelector('.footer');
    if (existing) existing.remove();

    // All footer links are absolute from site root
    var bizCore = siteRoot + 'business/project-core/';
    var techCore = siteRoot + 'technical/project-core/';
    var techSdlc = siteRoot + 'technical/project-sdlc/';

    var footer = document.createElement('footer');
    footer.className = 'footer footer--compact';
    footer.innerHTML =
      '<div class="container">' +
        '<div class="footer__row">' +
          '<div class="footer__brand-col">' +
            '<span class="footer__logo">V</span>' +
            '<span class="footer__name">Vuniverse</span>' +
            '<span class="footer__by">by Frederick Bloom</span>' +
          '</div>' +
          '<div class="footer__links-col">' +
            '<a href="' + bizCore + 'index.html">Overview</a>' +
            '<a href="' + bizCore + 'features.html">Features</a>' +
            '<a href="' + bizCore + 'security.html">Security</a>' +
            '<a href="' + bizCore + 'pricing.html">Licensing</a>' +
            '<a href="' + techCore + 'architecture.html">Architecture</a>' +
            '<a href="' + techCore + 'cli-reference.html">CLI</a>' +
            '<a href="' + techCore + 'test-harness.html">Test Harness</a>' +
            '<a href="' + techSdlc + 'index.html">SDLC</a>' +
          '</div>' +
        '</div>' +
        '<div class="footer__bottom">' +
          '<div class="footer__copy">&copy; 2026-* <strong>Frederick Bloom</strong>. All rights reserved. &nbsp;|&nbsp; <strong>Hanaden</strong></div>' +
          '<div class="footer__license">AGPL-3.0-only &middot; Dual Licensed</div>' +
        '</div>' +
      '</div>';

    // Insert before script tags or at end of body
    var scripts = document.querySelectorAll('body > script');
    if (scripts.length > 0) {
      document.body.insertBefore(footer, scripts[0]);
    } else {
      document.body.appendChild(footer);
    }
  }

  // ==========================================================================
  // DOMContentLoaded
  // ==========================================================================
  document.addEventListener('DOMContentLoaded', function () {

    // --- Hamburger toggle ---
    var burger = document.querySelector('.nav__hamburger');
    var links = document.querySelector('.nav__links');
    if (burger && links) {
      burger.addEventListener('click', function () {
        links.classList.toggle('open');
      });
    }

    // --- Active page highlighting ---
    var currentPath = window.location.pathname;
    var navAnchors = document.querySelectorAll('.nav__links a');
    navAnchors.forEach(function (a) {
      var href = a.getAttribute('href');
      if (!href) return;
      var normalized = href.replace(/index\.html$/, '').replace(/\/$/, '');
      var currentNorm = currentPath.replace(/index\.html$/, '').replace(/\/$/, '');
      if (normalized && currentNorm.endsWith(normalized)) {
        a.classList.add('active');
      }
    });

    // --- Scroll-in animation observer ---
    if ('IntersectionObserver' in window) {
      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
            observer.unobserve(entry.target);
          }
        });
      }, { threshold: 0.1 });
      document.querySelectorAll('.observe-in').forEach(function (el) {
        observer.observe(el);
      });
    }

    // --- Auto-sidebar generation for pages without one ---
    if (!document.querySelector('.page-sidebar')) {
      var sections = document.querySelectorAll('section[id]');
      if (sections.length >= 2) {
        var sidebar = document.createElement('aside');
        sidebar.className = 'page-sidebar';
        sidebar.innerHTML = '<div class="page-sidebar__heading">On This Page</div>';
        var ul = document.createElement('ul');
        ul.className = 'page-sidebar__links';
        sections.forEach(function (sec) {
          var heading = sec.querySelector('h2, h3');
          if (!heading) return;
          var li = document.createElement('li');
          var a = document.createElement('a');
          a.href = '#' + sec.id;
          a.textContent = heading.textContent.substring(0, 40);
          li.appendChild(a);
          ul.appendChild(li);
        });
        sidebar.appendChild(ul);

        var nav = document.querySelector('.nav');
        var footer = document.querySelector('.footer');
        var main = document.createElement('div');
        main.className = 'page-layout';
        var mainInner = document.createElement('div');
        mainInner.className = 'page-layout__main';

        var toMove = [];
        var el = nav ? nav.nextElementSibling : document.body.firstElementChild;
        while (el && el !== footer && el !== sidebar && el.tagName !== 'SCRIPT') {
          toMove.push(el);
          el = el.nextElementSibling;
        }
        toMove.forEach(function (node) { mainInner.appendChild(node); });

        main.appendChild(mainInner);
        main.appendChild(sidebar);
        if (footer) {
          footer.parentNode.insertBefore(main, footer);
        } else {
          document.body.appendChild(main);
        }
      }
    }

    // --- Inject DRY footer ---
    injectFooter();

    // --- Scroll-spy for sidebar active state ---
    var sidebarLinks = document.querySelectorAll('.page-sidebar__links a');
    if (sidebarLinks.length > 0) {
      var spySections = [];
      sidebarLinks.forEach(function (a) {
        var id = a.getAttribute('href');
        if (id && id.startsWith('#')) {
          var target = document.getElementById(id.substring(1));
          if (target) spySections.push({ el: target, link: a });
        }
      });
      if (spySections.length > 0) {
        var spyObserver = new IntersectionObserver(function (entries) {
          entries.forEach(function (entry) {
            var match = spySections.find(function (s) { return s.el === entry.target; });
            if (match && entry.isIntersecting) {
              sidebarLinks.forEach(function (l) { l.classList.remove('active'); });
              match.link.classList.add('active');
            }
          });
        }, { rootMargin: '-20% 0px -60% 0px' });
        spySections.forEach(function (s) { spyObserver.observe(s.el); });
      }
    }

    // --- Mermaid initialization ---
    if (typeof mermaid !== 'undefined') {
      mermaid.initialize({
        startOnLoad: true,
        theme: 'dark',
        themeVariables: {
          darkMode: true,
          background: '#0a0f1d',
          primaryColor: '#1a2744',
          primaryBorderColor: '#3bf5a9',
          primaryTextColor: '#e2e8f0',
          secondaryColor: '#7c3aed',
          tertiaryColor: '#111827',
          lineColor: '#3bf5a9',
          textColor: '#e2e8f0',
          mainBkg: '#111827',
          nodeBorder: '#3bf5a9',
          clusterBkg: 'rgba(17,24,39,0.6)',
          clusterBorder: '#1e293b',
          titleColor: '#ffffff',
          edgeLabelBackground: '#0a0f1d',
          nodeTextColor: '#e2e8f0'
        },
        flowchart: { curve: 'basis', padding: 10 },
        fontFamily: 'Inter, system-ui, sans-serif',
        fontSize: 13
      });
    }

    // --- Particle canvas (hub page only) ---
    var canvas = document.getElementById('particles');
    if (canvas && canvas.getContext) {
      initParticles(canvas);
    }
  });

  // ==========================================================================
  // Particles
  // ==========================================================================
  function initParticles(canvas) {
    var ctx = canvas.getContext('2d');
    var particles = [];
    var PARTICLE_COUNT = 60;
    var MAX_DIST = 120;

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }
    resize();
    window.addEventListener('resize', resize);

    for (var i = 0; i < PARTICLE_COUNT; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        vx: (Math.random() - 0.5) * 0.3,
        vy: (Math.random() - 0.5) * 0.3,
        r: Math.random() * 1.5 + 0.5
      });
    }

    function draw() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      for (var i = 0; i < particles.length; i++) {
        for (var j = i + 1; j < particles.length; j++) {
          var dx = particles[i].x - particles[j].x;
          var dy = particles[i].y - particles[j].y;
          var dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < MAX_DIST) {
            var alpha = (1 - dist / MAX_DIST) * 0.15;
            ctx.strokeStyle = 'rgba(59, 245, 169, ' + alpha + ')';
            ctx.lineWidth = 0.5;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.stroke();
          }
        }
      }
      for (var k = 0; k < particles.length; k++) {
        var p = particles[k];
        ctx.fillStyle = 'rgba(59, 245, 169, 0.6)';
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.fill();
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
        if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
      }
      requestAnimationFrame(draw);
    }
    draw();
  }
})();
