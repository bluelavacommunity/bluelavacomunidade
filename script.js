/* script.js — Minimal interactions: mobile nav toggle, smooth scrolling, and year injection */

document.addEventListener('DOMContentLoaded', function(){
  // Mobile nav toggle
  var navToggle = document.getElementById('navToggle');
  var siteNav = document.getElementById('siteNav');
  navToggle && navToggle.addEventListener('click', function(){
    var expanded = this.getAttribute('aria-expanded') === 'true';
    this.setAttribute('aria-expanded', String(!expanded));
    if(siteNav) siteNav.style.display = expanded ? 'none' : 'flex';
  });

  // Smooth scrolling for internal links
  document.querySelectorAll('a[href^="#"]').forEach(function(anchor){
    anchor.addEventListener('click', function(e){
      var href = anchor.getAttribute('href');
      if (href === '#') return; // placeholder
      e.preventDefault();
      var target = document.querySelector(href);
      if(target){ target.scrollIntoView({behavior:'smooth',block:'start'}); }
    });
  });

  // Current year in footer
  var yearEl = document.getElementById('year');
  if(yearEl) yearEl.textContent = new Date().getFullYear();
});
