module.exports = {
    content: [
        './_layouts/**/*.{html,js}',
        './_includes/**/*.{html,js}',
        './*.{html,js}',
    ],
    theme: {
        // ...
        extend: {
            fontFamily: {
                'ibm': ['IBM Plex Mono', 'monospace'],
            },
        },
    },
    plugins: [
        require('@tailwindcss/typography'),
        // ...
    ],
}