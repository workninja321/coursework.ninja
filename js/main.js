/* ============================================
   COURSEWORK NINJA - MAIN JAVASCRIPT
   Hero Section & Navigation
   ============================================ */

(function() {
  'use strict';

  // ========== SELECTORS ==========
  const selectors = {
    header: '#header',
    navToggle: '#nav-toggle',
    mobileMenu: '#mobile-menu',
    mobileLinks: '.header__mobile-link',
    desktopLinks: '.header__link'
  };

  // ========== STICKY HEADER ==========
  function initStickyHeader() {
    const header = document.querySelector(selectors.header);
    if (!header) return;

    let ticking = false;

    function updateHeader() {
      const currentScroll = window.pageYOffset;

      if (currentScroll > 10) {
        header.classList.add('header--scrolled');
      } else {
        header.classList.remove('header--scrolled');
      }

      ticking = false;
    }

    window.addEventListener('scroll', function() {
      if (!ticking) {
        window.requestAnimationFrame(updateHeader);
        ticking = true;
      }
    }, { passive: true });

    // Initial check
    updateHeader();
  }

  // ========== MOBILE MENU ==========
  function initMobileMenu() {
    const toggle = document.querySelector(selectors.navToggle);
    const menu = document.querySelector(selectors.mobileMenu);
    const closeBtn = document.querySelector('#mobile-close');
    const links = document.querySelectorAll(selectors.mobileLinks);

    if (!toggle || !menu) return;

    function openMenu() {
      toggle.setAttribute('aria-expanded', 'true');
      toggle.setAttribute('aria-label', 'Close menu');
      menu.classList.add('is-open');
      document.body.classList.add('nav-open');

      // Focus first menu item for accessibility
      const firstLink = menu.querySelector('a');
      if (firstLink) {
        setTimeout(() => firstLink.focus(), 100);
      }
    }

    function closeMenu() {
      toggle.setAttribute('aria-expanded', 'false');
      toggle.setAttribute('aria-label', 'Open menu');
      menu.classList.remove('is-open');
      document.body.classList.remove('nav-open');
    }

    function toggleMenu() {
      const isOpen = toggle.getAttribute('aria-expanded') === 'true';
      if (isOpen) {
        closeMenu();
      } else {
        openMenu();
      }
    }

    // Toggle button click
    toggle.addEventListener('click', toggleMenu);

    // Close button click
    if (closeBtn) {
      closeBtn.addEventListener('click', closeMenu);
    }

    // Close on link click
    links.forEach(function(link) {
      link.addEventListener('click', closeMenu);
    });

    // Close on escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && menu.classList.contains('is-open')) {
        closeMenu();
        toggle.focus();
      }
    });

    // Close on click outside
    document.addEventListener('click', function(e) {
      if (menu.classList.contains('is-open') &&
          !menu.contains(e.target) &&
          !toggle.contains(e.target)) {
        closeMenu();
      }
    });

    // Handle tab trapping within mobile menu
    menu.addEventListener('keydown', function(e) {
      if (e.key !== 'Tab') return;

      const focusableElements = menu.querySelectorAll('a, button');
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    });
  }

  // ========== SMOOTH SCROLL ==========
  function initSmoothScroll() {
    const links = document.querySelectorAll('a[href^="#"]');
    const header = document.querySelector(selectors.header);

    links.forEach(function(link) {
      link.addEventListener('click', function(e) {
        const targetId = this.getAttribute('href');

        if (targetId === '#' || targetId === '#main-content') return;

        const target = document.querySelector(targetId);
        if (!target) return;

        e.preventDefault();

        const headerHeight = header ? header.offsetHeight : 0;
        const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - headerHeight - 20;

        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });

        // Update URL without jumping
        history.pushState(null, null, targetId);

        // Set focus on target for accessibility
        target.setAttribute('tabindex', '-1');
        target.focus({ preventScroll: true });
      });
    });
  }

  // ========== ACTIVE NAV HIGHLIGHTING ==========
  function initActiveNav() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll(selectors.desktopLinks);

    if (!sections.length || !navLinks.length) return;

    function updateActiveLink() {
      const scrollPos = window.pageYOffset + 100;

      sections.forEach(function(section) {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.offsetHeight;
        const sectionId = section.getAttribute('id');

        if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
          navLinks.forEach(function(link) {
            link.classList.remove('active');
            if (link.getAttribute('href') === '#' + sectionId) {
              link.classList.add('active');
            }
          });
        }
      });
    }

    let ticking = false;
    window.addEventListener('scroll', function() {
      if (!ticking) {
        window.requestAnimationFrame(function() {
          updateActiveLink();
          ticking = false;
        });
        ticking = true;
      }
    }, { passive: true });

    // Initial check
    updateActiveLink();
  }

  // ========== HERO CAROUSEL ==========
  function initHeroCarousel() {
    const carousel = document.querySelector('.hero-carousel');
    if (!carousel) return;

    const slides = carousel.querySelectorAll('.hero-carousel__slide');
    const indicators = carousel.querySelectorAll('.hero-carousel__indicator');

    if (!slides.length) return;

    let currentSlide = 0;
    let autoplayInterval = null;
    const autoplayDelay = 3000; // 3 seconds per slide
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function goToSlide(index) {
      // Remove active class from all slides and indicators
      slides.forEach(function(slide) {
        slide.classList.remove('hero-carousel__slide--active');
      });
      indicators.forEach(function(indicator) {
        indicator.classList.remove('hero-carousel__indicator--active');
      });

      // Add active class to current slide and indicator
      slides[index].classList.add('hero-carousel__slide--active');
      indicators[index].classList.add('hero-carousel__indicator--active');

      currentSlide = index;
    }

    function nextSlide() {
      const next = (currentSlide + 1) % slides.length;
      goToSlide(next);
    }

    function startAutoplay() {
      if (reducedMotion) return;
      stopAutoplay();
      autoplayInterval = setInterval(nextSlide, autoplayDelay);
    }

    function stopAutoplay() {
      if (autoplayInterval) {
        clearInterval(autoplayInterval);
        autoplayInterval = null;
      }
    }

    // Click handlers for indicators
    indicators.forEach(function(indicator, index) {
      indicator.addEventListener('click', function() {
        goToSlide(index);
        startAutoplay(); // Restart autoplay after manual navigation
      });
    });

    // Pause autoplay on hover
    carousel.addEventListener('mouseenter', stopAutoplay);
    carousel.addEventListener('mouseleave', startAutoplay);

    // Pause autoplay on focus for accessibility
    carousel.addEventListener('focusin', stopAutoplay);
    carousel.addEventListener('focusout', startAutoplay);

    // Keyboard navigation
    carousel.addEventListener('keydown', function(e) {
      if (e.key === 'ArrowLeft') {
        const prev = (currentSlide - 1 + slides.length) % slides.length;
        goToSlide(prev);
        startAutoplay();
      } else if (e.key === 'ArrowRight') {
        nextSlide();
        startAutoplay();
      }
    });

    // Start autoplay
    startAutoplay();
  }

  // ========== BUTTON RIPPLE EFFECT ==========
  function initRippleEffect() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    const buttons = document.querySelectorAll('.btn');

    buttons.forEach(function(btn) {
      btn.addEventListener('click', function(e) {
        const rect = this.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        const ripple = document.createElement('span');
        ripple.className = 'btn-ripple';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';

        this.appendChild(ripple);

        setTimeout(function() {
          ripple.remove();
        }, 600);
      });
    });

    // Add ripple styles dynamically
    if (!document.querySelector('#ripple-styles')) {
      const style = document.createElement('style');
      style.id = 'ripple-styles';
      style.textContent = `
        .btn-ripple {
          position: absolute;
          width: 20px;
          height: 20px;
          background: rgba(255, 255, 255, 0.4);
          border-radius: 50%;
          transform: scale(0);
          animation: ripple-effect 0.6s ease-out;
          pointer-events: none;
        }
        @keyframes ripple-effect {
          to {
            transform: scale(15);
            opacity: 0;
          }
        }
      `;
      document.head.appendChild(style);
    }
  }

  // ========== HERO CONTENT ANIMATION ==========
  function initHeroAnimation() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    const heroContent = document.querySelector('.hero__content');
    if (!heroContent) return;

    // Add entrance animation class
    heroContent.style.opacity = '0';
    heroContent.style.transform = 'translateY(30px)';
    heroContent.style.transition = 'opacity 0.8s ease, transform 0.8s ease';

    // Trigger animation after a short delay
    setTimeout(function() {
      heroContent.style.opacity = '1';
      heroContent.style.transform = 'translateY(0)';
    }, 100);
  }

  // ========== TESTIMONIALS CAROUSEL ==========
  function initTestimonialsCarousel() {
    const carousel = document.querySelector('.testimonials__carousel');
    if (!carousel) return;

    const viewport = carousel.querySelector('.testimonials__viewport');
    const track = carousel.querySelector('.testimonials__track');
    const slides = carousel.querySelectorAll('.testimonial-slide');
    const dots = carousel.querySelectorAll('.testimonials__dot');
    const prevBtn = carousel.querySelector('.testimonials__nav--prev');
    const nextBtn = carousel.querySelector('.testimonials__nav--next');

    if (!slides.length || !track || !viewport) return;

    let currentSlide = 0;
    let autoplayInterval = null;
    const autoplayDelay = 6000; // 6 seconds per slide
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function goToSlide(index) {
      // Update track position
      track.style.transform = 'translateX(-' + (index * 100) + '%)';

      // Update dots
      dots.forEach(function(dot, i) {
        dot.classList.toggle('testimonials__dot--active', i === index);
      });

      currentSlide = index;
    }

    function nextSlide() {
      const next = (currentSlide + 1) % slides.length;
      goToSlide(next);
    }

    function prevSlide() {
      const prev = (currentSlide - 1 + slides.length) % slides.length;
      goToSlide(prev);
    }

    function startAutoplay() {
      if (reducedMotion) return;
      stopAutoplay();
      autoplayInterval = setInterval(nextSlide, autoplayDelay);
    }

    function stopAutoplay() {
      if (autoplayInterval) {
        clearInterval(autoplayInterval);
        autoplayInterval = null;
      }
    }

    // Navigation button handlers
    if (prevBtn) {
      prevBtn.addEventListener('click', function() {
        prevSlide();
        startAutoplay();
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', function() {
        nextSlide();
        startAutoplay();
      });
    }

    // Dot navigation
    dots.forEach(function(dot, index) {
      dot.addEventListener('click', function() {
        goToSlide(index);
        startAutoplay();
      });
    });

    // Pause autoplay on hover
    carousel.addEventListener('mouseenter', stopAutoplay);
    carousel.addEventListener('mouseleave', startAutoplay);

    // Pause autoplay on focus for accessibility
    carousel.addEventListener('focusin', stopAutoplay);
    carousel.addEventListener('focusout', startAutoplay);

    // Keyboard navigation
    carousel.addEventListener('keydown', function(e) {
      if (e.key === 'ArrowLeft') {
        prevSlide();
        startAutoplay();
      } else if (e.key === 'ArrowRight') {
        nextSlide();
        startAutoplay();
      }
    });

    // Touch/swipe support
    let touchStartX = 0;
    let touchEndX = 0;

    viewport.addEventListener('touchstart', function(e) {
      touchStartX = e.changedTouches[0].screenX;
      stopAutoplay();
    }, { passive: true });

    viewport.addEventListener('touchend', function(e) {
      touchEndX = e.changedTouches[0].screenX;
      handleSwipe();
      startAutoplay();
    }, { passive: true });

    function handleSwipe() {
      const swipeThreshold = 50;
      const diff = touchStartX - touchEndX;

      if (Math.abs(diff) > swipeThreshold) {
        if (diff > 0) {
          nextSlide();
        } else {
          prevSlide();
        }
      }
    }

    // Start autoplay
    startAutoplay();
  }

  // ========== LAZY LOADING FOR FUTURE IMAGES ==========
  function initLazyLoad() {
    const lazyImages = document.querySelectorAll('img[data-src]');

    if (!lazyImages.length) return;

    if ('IntersectionObserver' in window) {
      const imageObserver = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            img.classList.add('loaded');
            imageObserver.unobserve(img);
          }
        });
      }, {
        rootMargin: '50px 0px'
      });

      lazyImages.forEach(function(img) {
        imageObserver.observe(img);
      });
    } else {
      // Fallback for older browsers
      lazyImages.forEach(function(img) {
        img.src = img.dataset.src;
        img.removeAttribute('data-src');
      });
    }
  }

  // ========== BLOG CATEGORY FILTER ==========
  function initBlogCategoryFilter() {
    const categoryBar = document.querySelector('.blog-index-categories');
    if (!categoryBar) return;

    const buttons = categoryBar.querySelectorAll('.blog-index-category');
    const cards = document.querySelectorAll('.blog-card');

    if (!buttons.length || !cards.length) return;

    function normalize(value) {
      return (value || '').trim().toLowerCase();
    }

    function setActive(activeButton) {
      buttons.forEach(function(button) {
        const isActive = button === activeButton;
        button.classList.toggle('blog-index-category--active', isActive);
        button.setAttribute('aria-pressed', isActive ? 'true' : 'false');
      });
    }

    function filter(category) {
      const normalized = normalize(category);
      const showAll = normalized === '' || normalized === 'all posts' || normalized === 'all';
      let visible = 0;

      cards.forEach(function(card) {
        const label = card.querySelector('.blog-card__category');
        const labelText = normalize(label ? label.textContent : '');
        const matches = showAll || (labelText && labelText === normalized);

        card.style.display = matches ? '' : 'none';
        if (matches) {
          visible += 1;
        }
      });

      const emptyState = document.querySelector('.blog-empty');
      if (emptyState) {
        emptyState.hidden = visible > 0;
      }
    }

    buttons.forEach(function(button) {
      button.addEventListener('click', function() {
        const category = button.getAttribute('data-category') || button.textContent;
        setActive(button);
        filter(category);
      });
    });

    const initial = categoryBar.querySelector('.blog-index-category--active') || buttons[0];
    if (initial) {
      const initialCategory = initial.getAttribute('data-category') || initial.textContent;
      setActive(initial);
      filter(initialCategory);
    }
  }

  // ========== ROADMAP FILTERS ==========
  function initRoadmapFilters() {
    const filterWrap = document.querySelector('[data-roadmap-filters]');
    if (!filterWrap) return;

    const filterButtons = filterWrap.querySelectorAll('[data-filter-group][data-filter-value]');
    const resetButton = filterWrap.querySelector('[data-filter-reset]');
    const cards = document.querySelectorAll('.roadmap-card');
    const emptyState = document.querySelector('[data-roadmap-empty]');

    if (!filterButtons.length || !cards.length) return;

    function normalize(value) {
      return (value || '').trim().toLowerCase();
    }

    function getActiveFilters() {
      const active = {};
      filterButtons.forEach(function(button) {
        if (!button.classList.contains('is-active')) return;
        const group = normalize(button.getAttribute('data-filter-group'));
        const value = normalize(button.getAttribute('data-filter-value'));
        if (!group || !value) return;
        if (!active[group]) active[group] = [];
        active[group].push(value);
      });
      return active;
    }

    function matchesGroup(card, group, values) {
      if (!values || !values.length) return true;
      const attr = normalize(card.getAttribute('data-' + group));
      if (!attr) return false;
      const tokens = attr.split(/\s+/).filter(Boolean);
      return values.some(function(value) {
        return tokens.includes(value);
      });
    }

    function applyFilters() {
      const active = getActiveFilters();
      let visibleCount = 0;

      cards.forEach(function(card) {
        const matches = Object.keys(active).every(function(group) {
          return matchesGroup(card, group, active[group]);
        });

        card.hidden = !matches;
        if (matches) visibleCount += 1;
      });

      if (emptyState) {
        emptyState.classList.toggle('is-visible', visibleCount === 0);
      }
    }

    function setResetActive(isActive) {
      if (!resetButton) return;
      resetButton.classList.toggle('is-active', isActive);
      resetButton.setAttribute('aria-pressed', isActive ? 'true' : 'false');
    }

    filterButtons.forEach(function(button) {
      button.addEventListener('click', function() {
        if (button.disabled) return;
        const isActive = button.classList.toggle('is-active');
        button.setAttribute('aria-pressed', isActive ? 'true' : 'false');
        const anyActive = Array.from(filterButtons).some(function(btn) {
          return btn.classList.contains('is-active');
        });
        setResetActive(!anyActive);
        applyFilters();
      });
    });

    if (resetButton) {
      resetButton.addEventListener('click', function() {
        filterButtons.forEach(function(button) {
          button.classList.remove('is-active');
          button.setAttribute('aria-pressed', 'false');
        });
        setResetActive(true);
        applyFilters();
      });
    }

    applyFilters();
  }

  // ========== ROADMAP TIMELINE ==========
  function initRoadmapTimeline() {
    const headers = document.querySelectorAll('.roadmap-phase__header');
    if (!headers.length) return;

    headers.forEach(function(header) {
      header.addEventListener('click', function() {
        const phase = this.closest('.roadmap-phase');
        if (!phase) return;
        const isExpanded = phase.classList.contains('is-expanded');

        phase.classList.toggle('is-expanded');
        this.setAttribute('aria-expanded', isExpanded ? 'false' : 'true');
      });

      header.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          this.click();
        }
      });
    });
  }

  // ========== FAQ ACCORDION ==========
  function initFaqAccordion() {
    const faqQuestions = document.querySelectorAll('.faq__question');

    if (!faqQuestions.length) return;

    faqQuestions.forEach(function(question) {
      question.addEventListener('click', function() {
        const isExpanded = this.getAttribute('aria-expanded') === 'true';
        const answer = this.nextElementSibling;

        // Close all other answers in the same container (category or items)
        const container = this.closest('.faq__category') || this.closest('.faq__items') || this.closest('.blog-faq');
        if (container) {
          const otherQuestions = container.querySelectorAll('.faq__question');

          otherQuestions.forEach(function(otherQuestion) {
            if (otherQuestion !== question) {
              otherQuestion.setAttribute('aria-expanded', 'false');
              otherQuestion.nextElementSibling.classList.remove('is-open');
            }
          });
        }

        // Toggle current answer
        if (isExpanded) {
          this.setAttribute('aria-expanded', 'false');
          answer.classList.remove('is-open');
        } else {
          this.setAttribute('aria-expanded', 'true');
          answer.classList.add('is-open');
        }
      });

      // Keyboard accessibility
      question.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          this.click();
        }
      });
    });
  }

  // ========== ANIMATED NUMBER COUNTERS ==========
  function initCounterAnimation() {
    const counters = document.querySelectorAll('[data-count]');
    if (!counters.length) return;

    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function formatNumber(num, useComma) {
      if (useComma) {
        return num.toLocaleString('en-US');
      }
      return num.toString();
    }

    function animateCounter(counter) {
      // Prevent re-animation
      if (counter.dataset.animated === 'true') return;
      counter.dataset.animated = 'true';

      const target = parseInt(counter.dataset.count, 10);
      const suffix = counter.dataset.suffix || '';
      const useComma = counter.dataset.format === 'comma';
      const duration = 2000; // 2 seconds
      const startTime = performance.now();

      // If reduced motion, just show final value
      if (reducedMotion) {
        counter.textContent = formatNumber(target, useComma) + suffix;
        return;
      }

      function updateCounter(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);

        // Easing function (ease-out)
        const easeOut = 1 - Math.pow(1 - progress, 3);
        const currentValue = Math.floor(easeOut * target);

        counter.textContent = formatNumber(currentValue, useComma) + suffix;

        if (progress < 1) {
          requestAnimationFrame(updateCounter);
        } else {
          counter.textContent = formatNumber(target, useComma) + suffix;
        }
      }

      requestAnimationFrame(updateCounter);
    }

    // Check if element is in viewport
    function isInViewport(element) {
      const rect = element.getBoundingClientRect();
      return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
      );
    }

    // Use IntersectionObserver to trigger animation when visible
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            animateCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      }, {
        threshold: 0.1,
        rootMargin: '50px'
      });

      counters.forEach(function(counter) {
        // If already visible, animate immediately after short delay
        if (isInViewport(counter)) {
          setTimeout(function() {
            animateCounter(counter);
          }, 500);
        } else {
          observer.observe(counter);
        }
      });
    } else {
      // Fallback for older browsers
      counters.forEach(animateCounter);
    }
  }

  // ========== INITIALIZE ==========
  function init() {
    initStickyHeader();
    initMobileMenu();
    initSmoothScroll();
    initActiveNav();
    initHeroCarousel();
    initTestimonialsCarousel();
    initRippleEffect();
    initHeroAnimation();
    initLazyLoad();
    initBlogCategoryFilter();
    initRoadmapFilters();
    initRoadmapTimeline();
    initFaqAccordion();
    initCounterAnimation();

    // Log initialization
    console.log('Coursework Ninja: JS initialized');
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
