;; ---------------------------------------------------------------------------------------------------------------------
;; It is assumed that we're running on a little-endian processor, so the colour component byte order must be written to
;; memory in the order ABGR (Alpha, Blue, Green, Red)
;; ---------------------------------------------------------------------------------------------------------------------
(module
  (memory (export "memory") 4)

  (func $incr (param $val i32) (result i32) (i32.add (local.get $val) (i32.const 1)))

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Calculate a colour component value
  ;; Result = i32 between 0 and 255 using ($val / $max) * 255
  (func $colour_component
        (param $val i32)
        (param $max i32)
        (result i32)
    ;; Convert rounded f32 back to an i32
    (i32.trunc_f32_u
      ;; Round the f32 ratio of ($val / $max) * 255 to the nearest integer
      (f32.nearest
        ;; Multiply by 255
        (f32.mul
          ;; Calculate $val / $max
          (f32.div (f32.convert_i32_u (local.get $val))
                   (f32.convert_i32_u (local.get $max)))
          (f32.const 255)
        )
      )
    )
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Store the colour component values in little-endian order
  (func $store_pixel
        (param $offset i32)  ;; Pixel offset in memory
        (param $red    i32)
        (param $green  i32)
        (param $blue   i32)
        (param $alpha  i32)
        (result i32)         ;; Updated memory offset
    ;; Store the combined RGBA values at $offset
    (i32.store
      (local.get $offset)
      ;; The current pixel value is created by shifting each component part left by the appropriate number of bits then
      ;; OR'ing them together
      (i32.or
        (i32.or
          (i32.shl (local.get $alpha) (i32.const 24))
          (i32.shl (local.get $blue)  (i32.const 16))
        )
        (i32.or
          (i32.shl (local.get $green) (i32.const 8))
          (local.get $red)
        )
      )
    )

    ;; Add 4 to the offset and leave the new value on stack as the return value
    (local.tee $offset (i32.add (local.get $offset) (i32.const 4)))
  )

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Generate a colour square $size pixels wide
  ;; The $red and $alpha values are supplied by the client
  (func $gen_colour_square
        (export "generateColourSquare")
        (param $size  i32)    ;; Colour square width/height
        (param $red   i32)    ;; Red component value supplied by caller
        (param $alpha i32)    ;; Alpha channel value supplied by caller

    (local $x       i32)      ;; Horizontal axis counter
    (local $y       i32)      ;; Vertical axis counter
    (local $blue    i32)      ;; Blue colour component of current pixel
    (local $green   i32)      ;; Green colour component of current pixel
    (local $mem_loc i32)      ;; Current ABGR offset in canvas memory

    ;; Calculate canvas size in bytes and store at offset 0
    (i32.store (i32.const 0) (i32.mul (i32.mul (local.get $size) (local.get $size)) (i32.const 4)))

    ;; Canvas image data lives at offset 4
    (local.set $mem_loc (i32.const 4))

    ;; Initialise loop counters
    (local.set $x (i32.const 0))
    (local.set $y (i32.const 0))

    (block $rows
      ;; Green varies from 0 to 255 down the y axis
      (loop $row_loop
        ;; Terminate the outer loop when we reach the edge of the square
        (br_if $rows (i32.eq (local.get $y) (local.get $size)))

        ;; Calculate the current pixel's green component
        (local.set $green (call $colour_component (local.get $y) (local.get $size)))

        (block $cols
          ;; Blue varies from 0 to 255 along the x axis
          (loop $col_loop
            ;; Terminate the inner loop when we reach the edge of the square
            (br_if $cols (i32.eq (local.get $x) (local.get $size)))

            ;; Calculate the current pixel's blue component
            (local.set $blue (call $colour_component (local.get $x) (local.get $size)))

            ;; Store the new memory location returned from the call to $store_pixel
            (local.set $mem_loc
              ;; Store the four colour component values as the current pixel
              (call $store_pixel
                    (local.get $mem_loc)
                    (local.get $red)
                    (local.get $green)
                    (local.get $blue)
                    (local.get $alpha)
              )
            )

            (local.set $x (call $incr (local.get $x)))  ;; Increment inner loop counter
            br $col_loop
          )
        )

        (local.set $x (i32.const 0))                  ;; Reset inner loop counter
        (local.set $y (call $incr (local.get $y)))    ;; Increment outer loop counter

        br $row_loop
      )
    )
  )
)
