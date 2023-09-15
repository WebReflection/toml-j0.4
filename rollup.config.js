// This file generates /core.js minified version of the module, which is
// the default exported as npm entry.

import { nodeResolve } from "@rollup/plugin-node-resolve";
import terser from "@rollup/plugin-terser";

export default [
    {
        input: "./lib/toml.js",
        plugins: [nodeResolve(), terser()],
        output: {
            esModule: true,
            file: "./toml.js",
            sourcemap: true,
        },
    }
];
