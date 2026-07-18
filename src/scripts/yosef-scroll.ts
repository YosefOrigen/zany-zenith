const headerRow = document.querySelector('.header-row');
let lastScrollTop = 0;
const scrollThreshold = 200;

window.addEventListener('scroll', () => {
  const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
  const diff = Math.abs(currentScroll - lastScrollTop);

  if (diff > scrollThreshold) {
    if (currentScroll > lastScrollTop) {
      headerRow?.classList.add('hidden');
    } else {
      headerRow?.classList.remove('hidden');
    }
    lastScrollTop = currentScroll;
  }
});
