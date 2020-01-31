let cvs, ctx, img, instance

// *****************************************************************************
// Simple DOM accessor function
function $id(elementId) {
  return document.getElementById(elementId)
}

// Path to the WASM module
const wasmFilePath = './wasm_lib/colour_map.wasm'  

// *****************************************************************************
// Event handler for updating red slider text and regenerating a new colour
// square
const redSliderInput =
  red => {
    $id("redValue").innerHTML = red
    drawColourSquare(red, $id("alphaSlider").value)
  }

// *****************************************************************************
// Event handler for updating alpha slider text and regenerating a new colour
// square
const alphaSliderInput =
  alpha => {
    $id("alphaValue").innerHTML = alpha
    drawColourSquare($id("redSlider").value, alpha)
  }

// *****************************************************************************
// Event handler for canvas mousemove event
// *****************************************************************************
const canvasMouseMoveHandler =
  e => {
    $id("blueValue").innerHTML  = e.offsetY
    $id("greenValue").innerHTML = e.offsetX
  }

// *****************************************************************************
// Invoke WASM functionality to create the data for a colour square
const drawColourSquare =
  (red, alpha) => {
    // Generate colour square data
    // At the moment, the only way for a WASM function to return more than a
    // single number, is to write that data into WASM's linear memory, then have
    // the runtime of the calling language access that memory directly.
    // Consequently, the WASM function getColourSquare does not directly return
    // any data to JavaScript in the expected manner.
    // Instead, when this function terminates, JavaScript has access to WASM's
    // linear memory, and we can read the data directly from there
    instance.exports.getColourSquare(cvs.width, red, alpha)
    
    // Put the entire block of WASM linear memory into a Uint8Array; however,
    // this is more data than is needed for our image, so we must select only
    // the relevant range from this array
    let wasmMem = new Uint8Array(instance.exports.memory.buffer)

    // The first 4 bytes of WASM memory hold the length of the colour square
    // data.  Use this data to construct a 32-bit integer using little-endian
    // byte order.  That's a fancy way of saying:
    //
    // 1) Read the first four bytes in reverse order
    // 2) Shift the first three of these bytes left by 24, 16 and 8 bits
    //    respectively
    // 3) Bitwise OR all four values together to reconstruct the 32-bit length
    //    value
    let memLength = wasmMem[3] << 24 |
                    wasmMem[2] << 16 |
                    wasmMem[1] << 8  |
                    wasmMem[0]

    // Transfer the relevant slice of WASM linear memory directly into the
    // canvas image
    img.data.set(wasmMem.slice(4, memLength + 4))
    ctx.putImageData(img, 0, 0)
  }

// *****************************************************************************
// Create a WASM module instance
const startWasm =
  async pathToWasmFile => {
    // Fetch WASM file contents and transform them into a Unit8Array
    let response  = await fetch(pathToWasmFile)
    let wasmBytes = new Uint8Array(await response.arrayBuffer())

    // Instantiate the WebAssembly file
    let wasmObj = await WebAssembly.instantiate(wasmBytes, {})
    
    console.log("WASM module started")

    return wasmObj.instance
  }

// *****************************************************************************
// Everything starts here
const start =
  async () => {
    // Wait for our WASM instance to start up
    instance = await startWasm(wasmFilePath)

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
