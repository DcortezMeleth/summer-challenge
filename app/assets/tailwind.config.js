/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/summer_challenge_web/**/*.*ex",
  ],
  theme: {
    extend: {
      colors: {
        // Central theme tokens (single place to tweak the palette later).
        brand: {
          950: "#022C22",
          900: "#064E3B",
          800: "#065F46",
          700: "#047857",
          600: "#059669",
          500: "#10B981",
          200: "#A7F3D0",
          100: "#D1FAE5",
          50: "#ECFDF5",
        },
        ui: {
          950: "#0B1220",
          900: "#0F172A",
          800: "#1E293B",
          700: "#334155",
          600: "#475569",
          500: "#64748B",
          300: "#CBD5E1",
          200: "#E2E8F0",
          100: "#F1F5F9",
          50: "#F8FAFC",
        },
      },
      boxShadow: {
        // Slightly punchier shadow for a "sporty card" feel.
        sport: "0 10px 25px -15px rgba(2, 44, 34, 0.45)",
      },
    },
  },
  plugins: [],
};


