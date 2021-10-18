# WebAssembly `colour_square` Generator

A small WebAssembly Text program that generates the RGBA data needed to display a simple colour square 511 pixels wide.

The green value varies down the vertical axis, and the blue value varies along the horizontal access.
The red and alpha values are supplied from the sliders on the UI.

As the red and alpha sliders are adjusted, the colour square is recalculated and the WASM execution time is displayed.

![Screenshot](./Screenshot.png)

The WASM module interacts with JavaScript by means of a shared block of linear memory:

* WASM writes to linear memory as a sequence of unsigned, 32-bit integers
* JavaScript picks up this memory as a `Uint8Array` and visualises it as a canvas image

## Prequisites

The WebAssembly Text file needs to be compiled into a WASM module.
Therefore you need a tool such as `wat2wasm` available from the [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt) (or `wabt`)

`wabt` can either be installed by building it directly from the Git repository listed above, or if you already have the [WebAssembly Package Manager](https://wapm.io/package/wabt) installed, you can install it using the command `wapm install wabt`.

## Setup Instructions

1. Clone this repo into some local development directory

    ```bash
    cd <some_development_directory>
    git clone https://github.com/ChrisWhealy/colour_map.git
    ```

1. Compile WAT source code (Optional)

    Compile the WebAssembly Text file

    ```bash
    wat2wasm colour_square.wat
    ```

    This will create the file `colour_square.wasm`

1. Change back to the main repo folder and start your Web Server using the local directory as the document root

    ```bash
    $ python3 -m http.server
    Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
    ```

1. In your browser, visit [http://0.0.0.0:8000](http://0.0.0.0:8000) and the screen will display the colour square shown above.

    Move the red and alpha sliders left and right, and the colour square is immediately recalculated using that particular value for the red component of each pixel.
