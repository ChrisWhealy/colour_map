(module
  ;; *******************************************************************************************************************
  ;; Private API functions
  ;; *******************************************************************************************************************
  
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Integer increment
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (func $incr (param $val i32) (result i32) (i32.add (get_local $val) (i32.const 1)))

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Calculate a colour component value as an integer between 0 and 255 using ($val / $max) * 255
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (func $colour-component (param $val i32) (param $max i32) (result i32)
    ;; Convert already rounded f32 back to an i32
    (i32.trunc_f32_u
      ;; Round the f32 ratio of ($val / $max) * 255 to the nearest integer
      (f32.nearest
        ;; Multiply by 255
        (f32.mul
          ;; Calculate $val / $max
          (f32.div
            ;; Convert i32 parameters to f32s
            (f32.convert_i32_u (get_local $val))
            (f32.convert_i32_u (get_local $max)))
          (f32.const 255)
        )
      )
    )
  )

  ;; *******************************************************************************************************************
  ;; Public API functions
  ;; *******************************************************************************************************************

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Dummy start function called when WASM module is instantiated
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (func $_start)

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Generate a colour square $size pixels wide/high using the supplied fixed value for $red
  ;; This assumes we're running on a little-endian processor, so the colour component byte order is RGBA
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (func $gen-colour-square
    (param $size  i32)        ;; Colour square width/height
    (param $red   i32)        ;; Red component value supplied by caller
    (param $alpha i32)        ;; Alpha channel component value supplied by caller

    (local $x       i32)      ;; Horizontal axis counter
    (local $y       i32)      ;; Vertical axis counter
    (local $blue    i32)      ;; Blue colour component of current pixel
    (local $green   i32)      ;; Blue colour component of current pixel
    (local $mem-loc i32)      ;; Current RGBA offset in color square
    
    ;; Write the length of colour square data in bytes as an i32 to offset 0
    ;; This will always be 4 * $size * $size when interpreted as a JavaScript Uint8Array
    (i32.store (i32.const 0)
               (i32.mul (i32.const 4)
                        (i32.mul (get_local $size)
                                 (get_local $size))))

    ;; Set memory offset to 4 since the colour square data follows on from the preceding i32 length value
    (set_local $mem-loc (i32.const 4))

    (block
      ;; Initialise loop counters
      (set_local $x (i32.const 0))
      (set_local $y (i32.const 0))

      ;; Blue varies from 0 to 255 down the y axis
      (loop
        ;; Terminate the outer loop when we reach the edge of the square
        (br_if 1 (i32.eq (get_local $y) (get_local $size)))

        ;; Calculate the current pixel's blue component
        (set_local $blue (call $colour-component (get_local $y) (get_local $size)))

        (block
          ;; Green varies from 0 to 255 along the x axis
          (loop
            ;; Terminate the inner loop when we reach the edge of the square
            (br_if 1 (i32.eq (get_local $x) (get_local $size)))

            ;; Calculate the current pixel's green component
            (set_local $green (call $colour-component (get_local $x) (get_local $size)))

            ;; Store each colour component value and bump the memory location
            ;; Red
            (i32.store8 (get_local $mem-loc) (get_local $red))
            (set_local $mem-loc (call $incr (get_local $mem-loc)))

            ;; Green
            (i32.store8 (get_local $mem-loc) (get_local $green))
            (set_local $mem-loc (call $incr (get_local $mem-loc)))

            ;; Blue
            (i32.store8 (get_local $mem-loc) (get_local $blue))
            (set_local $mem-loc (call $incr (get_local $mem-loc)))

            ;; Alpha
            (i32.store8 (get_local $mem-loc) (get_local $alpha))
            (set_local $mem-loc (call $incr (get_local $mem-loc)))

            ;; Increment inner loop counter
            (set_local $x (call $incr (get_local $x)))

            (br 0)
          )
        )

        (set_local $x (i32.const 0))                  ;; Reset inner loop counter
        (set_local $y (call $incr (get_local $y)))    ;; Increment outer loop counter

        (br 0)
      )
    )
  )

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Declare the use of 4 64Kb memory pages and export it using the name "memory"
  ;; This is just enough memory in which to store the RGBA data for a 255*255 colour square
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (memory (export "memory") 4)

  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ;; Export functions for public API
  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  (export "_start"             (func $_start))
  (export "getColourSquare"    (func $gen-colour-square))
)
