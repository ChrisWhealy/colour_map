let cvs, ctx, img, wasmModExports

// Path to the WASM module
const wasmFilePath = './colour_square.wasm'

const toMilliTenths = val => Math.round(val * 10000) / 10000
const $id = elementId => document.getElementById(elementId)

// Event handler for updating red slider text and regenerating a new colour square
const redSliderInput =
  red => {
    $id("redValue").innerHTML = red
    drawColourSquare(red, $id("alphaSlider").value)
  }

// Event handler for updating alpha slider text and regenerating a new colour square
const alphaSliderInput =
  alpha => {
    $id("alphaValue").innerHTML = alpha
    drawColourSquare($id("redSlider").value, alpha)
  }

// Event handler for canvas mousemove event
const canvasMouseMoveHandler =
  e => {
    $id("blueValue").innerHTML  = e.offsetX
    $id("greenValue").innerHTML = e.offsetY
  }

// Convert 4 bytes from Uint8Array `m` index `i` as a little-endian i32
const bytesAsI32 = (m, i) => m[i+3] << 24 | m[i+2] << 16 | m[i+1] << 8 | m[i]

// Invoke WASM functionality to create the data for a colour square
const drawColourSquare =
  (red, alpha) => {
    let then = window.performance.now()
    // Generate colour square data
    wasmModExports.generateColourSquare(cvs.width, red, alpha)
    $id("wasmExecTime").innerHTML = `${toMilliTenths(window.performance.now() - then)}ms`

    let wasmMem = new Uint8Array(wasmModExports.memory.buffer)
    let memLength = bytesAsI32(wasmMem, 0)

    // Transfer the relevant slice of WASM linear memory directly into the
    // canvas image
    img.data.set(wasmMem.slice(4, memLength + 4))
    ctx.putImageData(img, 0, 0)
  }

// Off we go...
const start =
  async () => {
    let wasmMod = await WebAssembly.instantiateStreaming(fetch(wasmFilePath))
    wasmModExports = wasmMod.instance.exports

    // Provide values for the variables used in function drawColourSquare
    cvs = $id("canvas")
    ctx = cvs.getContext('2d')
    img = ctx.createImageData(cvs.clientWidth, cvs.height)

    // Add mouse move handler to canvas
    cvs.onmousemove = canvasMouseMoveHandler

    // Draw the initial colour square
    let redVal   = $id("redSlider").value
    let alphaVal = $id("alphaSlider").value

    $id("redValue").innerHTML   = redVal
    $id("alphaValue").innerHTML = alphaVal

    drawColourSquare(redVal, alphaVal)
  }
