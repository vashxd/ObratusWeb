/**
 * Common JavaScript functions for the Obratus platform
 */

// Make sure Bootstrap components are properly initialized
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Bootstrap tooltips if present
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }

    // Initialize Bootstrap popovers if present
    if (typeof bootstrap !== 'undefined' && bootstrap.Popover) {
        var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
        popoverTriggerList.map(function (popoverTriggerEl) {
            return new bootstrap.Popover(popoverTriggerEl);
        });
    }

    // Ensure mobile navbar toggle works correctly
    var navbarToggler = document.querySelector('.navbar-toggler');
    if (navbarToggler) {
        navbarToggler.addEventListener('click', function() {
            var target = document.querySelector(this.getAttribute('data-bs-target'));
            if (target) {
                // Check if Bootstrap's collapse is properly working
                if (typeof bootstrap !== 'undefined' && bootstrap.Collapse) {
                    // Bootstrap is working, let it handle the toggle
                    console.log('Bootstrap is handling navbar toggle');
                } else {
                    // Bootstrap might not be loaded properly, manually toggle
                    console.log('Manually toggling navbar');
                    if (target.classList.contains('show')) {
                        target.classList.remove('show');
                    } else {
                        target.classList.add('show');
                    }
                }
            }
        });
    }
});
