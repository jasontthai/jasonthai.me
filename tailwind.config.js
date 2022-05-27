module.exports = {
    content: [
        './_layouts/**/*.{html,js}',
        './_includes/**/*.{html,js}',
        './*.{html,js}',
    ],
    theme: {
        // ...
    },
    plugins: [
        require('@tailwindcss/typography'),
        // ...
    ],
}