extensions [table]

globals [count-exit count-exit-0 count-exit-1 count-exit-2 id-pos-x id-pos-y how-many time how-many-0 how-many-1 how-many-2 changes_LtoR changes_RtoL]

patches-own [id free free-next updated vel nearest-patch nextpx nextpy desvel velmax]

;initialization of the model
to setup-line
  clear-all
  set changes_LtoR 0
  set changes_RtoL 0
  set how-many n-peds
  ;two arrays used to keep track of the id and position of the peds
  set id-pos-x table:make
  set id-pos-y table:make
  ask patches
  [
    set free true
    set free-next true
    set updated false
    set id "empty"
    set pcolor black
  ]
  let n how-many
  while [n > 0]
  [
    ask patch (min-pxcor + (n - 1)) 0
    [
      set free false
      set vel 0
      let xt (random 100)
      ifelse(xt <= (slow-cars * 100))
      [set velmax  4]
      [set velmax  6]
      set n n - 1
      set id how-many - n
      ifelse (id mod 10 = 0)
        [set pcolor white]
      [set pcolor id]
      table:put id-pos-x id pxcor
      table:put id-pos-y id pycor
    ]
  ]
  set count-exit 0.0
  set time 1
  reset-ticks
end

;function to add a ped every n timesteps, in a random free position
to add-ped-shuffled-parallel
  let my-id (table:length id-pos-x) + 1

  ask (one-of (patches with [free and pycor < lanes and pycor >= 0]))  ;cella libera random
  [
    set free false
    set id my-id
    set nextpx pxcor
    set nextpy pycor
    table:put id-pos-x my-id pxcor
    table:put id-pos-y my-id pycor
    set vel 0
    let xt (random 100)
    ifelse(xt <= (slow-cars * 100))
      [set velmax  4]
    [set velmax  6]
  ]
  set how-many how-many + 1
  set count-exit 0
  set count-exit-0 0
  set count-exit-1 0
  set count-exit-2 0
  set changes_LtoR 0
  set changes_RtoL 0
  set time 1
  show count patches with [free = false]
end

;main function for the parallel computation and update
to go-parallel
  lane-change-r-to-l
  lane-change-l-to-r
  forward-movement

  ;set variables gor graphs
  set how-many-0 count patches with [pycor = 0 and free = false]
  set how-many-1 count patches with [pycor = 1 and free = false]
  set how-many-2 count patches with [pycor = 2 and free = false]
  set time time + 1
  tick
  if (fundDiag and time >= time-for-it and (count patches with [free and pycor < lanes and pycor >= 0]) > 0)
  [add-ped-shuffled-parallel]

end

to lane-change-r-to-l
  ask patches[
    if (not free and pycor < 2 )
    [
      set nextpx pxcor
      set nextpy pycor
      let vel-mylane 0

      ;possible speed on my lane?
      let nextpx-mylane get-nextpx velmax (pycor)

      ifelse ((nextpx-mylane - pxcor) >= 0 )
          [
            set vel-mylane (nextpx-mylane - pxcor)
      ]
      [
        set vel-mylane 48 - abs (nextpx-mylane - pxcor) + 1
      ]

      ;can I overtake?
      if (vel-mylane - 1 < velmax and pycor < (lanes - 1) )
      [

        let temp-nextpx get-nextpx desvel (pycor + 1)
        let temp-vel 0
        let check-b check-backward 6 (pycor + 1)

        ;calculate possible new speed
        ifelse ((temp-nextpx - pxcor) >= 0 )
        [
          set temp-vel (temp-nextpx - pxcor)
        ]
        [
          set temp-vel 48 - abs (temp-nextpx - pxcor) + 1
        ]
        let ext ( random 10)

        ;do the overtake
        if(vel-mylane <= temp-vel and check-b = nobody and ext = 0)
        [
          set nextpy (pycor + 1)
          set changes_RtoL (changes_RtoL + 1)
        ]

      ]
    ]
  ]
  update-states
end


to lane-change-l-to-r
  ask patches[
    if (not free and pycor > 0 )
    [
      set nextpx pxcor
      set nextpy pycor
      let ext ( random 100)

      ;original rules
      ;let check-f-same check-forward (6 + 1 + voff) (pycor)
      ;let check-f-right-1 check-forward (6 + 1 + voff) (pycor - 1)

      ;custom rules
      let check-f-same check-forward ((2 * (vel + 1)) + 1) (pycor)
      let check-f-right-1 check-forward ((2 * (vel + 1)) + 1) (pycor - 1)


      let check-f-right-2 check-forward 6 (pycor - 1)
      let check-b-right check-backward 6 (pycor - 1)

      ;check possibility to overtake
      if ( pycor > 0  and ext < (p-l2r * 100)  and check-f-right-2 = nobody and check-b-right = nobody)
      [
        ;correction for congested traffic
        set nextpy (pycor - 1)
      ]
      if ( pycor > 0  and ext >= (p-l2r * 100) and check-f-right-1 = nobody and check-f-same = nobody)
      [
        set nextpy (pycor - 1)
        set changes_LtoR (changes_LtoR + 1)
      ]
    ]
  ]
  update-states
end

to forward-movement
  ask patches
  [
    if (not free)
    [

      ifelse (vel < velmax)[
        set desvel ( vel + 1 )
      ]
      [
        set desvel velmax
      ]

      ;randomization
      set nextpx get-nextpx-rand desvel  pycor
      set nextpy pycor

      ifelse ((nextpx - pxcor) >= 0 )
      [
        set vel (nextpx - pxcor)
      ]
      [
        set vel 48 - abs (nextpx - pxcor) + 1
      ]

      ;count for graphs
      if (nextpx > max-pxcor or (nextpx - pxcor) < 0)
      [
        set count-exit count-exit + 1
        if ( pycor = 0)
        [
          set count-exit-0 count-exit-0 + 1
        ]
        if ( pycor = 1)
        [
          set count-exit-1 count-exit-1 + 1
        ]
        if ( pycor = 2)
        [
          set count-exit-2 count-exit-2 + 1
        ]
      ]
    ]
  ]
  update-states
end

;do the real movement, set the next cell occupied and free the current cell
to update-states
  ask patches[
    if (not free)[
      ifelse (nextpx != pxcor or nextpy != pycor)
      [
        if (pxcor <= max-pxcor)
        [
          let my-id id
          let myvel vel
          let mymax velmax

          ask patch nextpx nextpy
          [
            set free-next false
            set id my-id
            set vel myvel
            set velmax mymax
            table:put id-pos-x id pxcor
            table:put id-pos-y id pycor
            ifelse (id mod 10 = 0)
            [set pcolor white]
            [set pcolor id]
          ]
        ]
        ;update current cell
        set id "empty"
        set free-next true
        set vel "null"
        set velmax "null"
        set pcolor black
        set nextpx pxcor
        set nextpy pycor
      ]
      [
        set free-next false
      ]
    ]
  ]
  ask patches [ set free free-next]
end


;Given len, the lenght of patch to consider ahead of my position, and lane, the y axis to consider, the function return the nearest patch in this area, considering the random deceleration
to-report get-nextpx-rand[len lane]
  let mypx pxcor
  let freepx "null"
  if (lane < lanes and len >= 3 and right-ban)[
    let temp-len 0
    let nearest-patch-left check-forward len ( lane + 1 )
    if( nearest-patch-left != nobody)[
      let new-nextpx [pxcor] of nearest-patch-left
      ifelse ((new-nextpx - pxcor) >= 0 )
        [
          set temp-len (new-nextpx - pxcor) - 1
      ]
      [
        set temp-len 48 - abs (new-nextpx - pxcor)
      ]
      if(temp-len > 0)[ set len temp-len]
    ]
  ]
  set nearest-patch check-forward len lane
  let ext ( random 100)
  ifelse nearest-patch != nobody
  [

    ifelse ((([pxcor] of nearest-patch) = (mypx + 1)) or (mypx = 24 and ([pxcor] of nearest-patch) = -24))
    [
      set freepx mypx
    ]
    [
      set freepx (([pxcor] of nearest-patch) - 1)
      if ( p-del != 0 )[
        if (ext <= (p-del * 100 ))
        [
          set freepx (freepx - 1)
          if(freepx < -24 )
          [set freepx (49 + freepx) ]
        ]
      ]
    ]
  ]
  [
    set freepx (mypx + len)
    if ( p-del != 0 )[
      if (ext <= (p-del * 100 ))
      [
        set freepx (freepx - 1)
        if(freepx < -24 )
        [set freepx (49 + freepx) ]
      ]
    ]
  ]
  report freepx
end

;Given len, the lenght of patch to consider ahead of my position, and lane, the y axis to consider, the function return the nearest patch in this area
to-report get-nextpx[len lane]
  let mypx pxcor
  let freepx "null"
  set nearest-patch check-forward len lane
  ifelse nearest-patch != nobody
  [
    ;correction for position near the boundary
    ifelse ((([pxcor] of nearest-patch) = (mypx + 1)) or (mypx = 24 and ([pxcor] of nearest-patch) = -24))
    [
      ;don't move
      set freepx mypx
    ]
    [
      ;move behind the next patch
      set freepx (([pxcor] of nearest-patch) - 1   )
    ]
  ]
  [
    ;move forward as desired
    set freepx (mypx + len)
  ]
  report freepx
end

;Given len, the lenght of patch to consider ahead of my position, and lane, the y axis to consider, the function return the nearest patch in this area
to-report check-forward[len lane]
  let mypx 0
  ifelse ( lane = pycor)[
    set mypx pxcor
  ]
  [
    set mypx pxcor - 1
  ]
  let next-patches nobody
  ;correction for positions near boundary
  ifelse (mypx + len) <= max-pxcor
  [
    set next-patches patches with [mypx + len  >= pxcor and pxcor > mypx and free = false and pycor = lane]
  ]
  [
    set next-patches patches with [((mypx + len  >= pxcor and pxcor > mypx) or (pxcor < (mypx + len - 48) and pxcor >= mypx - 48)) and free = false and pycor = lane]
  ]
  set nearest-patch min-one-of (next-patches ) [distance myself]
  ifelse nearest-patch != nobody
  [
    report nearest-patch
  ]
  [
    report nobody
  ]
end

;Given len, the lenght of patch to consider behind my position, and lane, the y axis to consider, the function return the nearest patch in this area
to-report check-backward[len lane]
  let mypx pxcor
  let past-patches nobody
  ifelse (mypx - len) >= min-pxcor
  [
    set past-patches patches with [mypx  >= pxcor and pxcor >= mypx - len and free = false and pycor = lane]
  ]
  [
    set past-patches patches with [((mypx  >= pxcor and pxcor >= mypx - len) or (pxcor >= (mypx - len + 48) and pxcor <= mypx + 48)) and free = false and pycor = lane]
  ]
  set nearest-patch min-one-of (past-patches ) [distance myself]
  ifelse nearest-patch != nobody
  [
    report nearest-patch
  ]
  [
    report nobody
  ]
end


;FUNCTIONS FOR DIAGRAMS

to-report flow
  report count-exit / time
end

to-report density
  report how-many / (max-pxcor * 2.0 * lanes + lanes)
end


to-report flow-2
  report count-exit-2 / time
end

to-report density-2
  report how-many-2 / (max-pxcor * 2.0 + 1 )
end

to-report flow-1
  report count-exit-1 / time
end

to-report density-1
  report how-many-1 / (max-pxcor * 2.0 + 1 )
end

to-report flow-0
  report count-exit-0 / time
end

to-report density-0
  report how-many-0 / (max-pxcor * 2.0 + 1 )
end

to-report lane-0-usage
  report how-many-0 / how-many
end

to-report lane-1-usage
  report how-many-1 / how-many
end

to-report lane-2-usage
  report how-many-2 / how-many
end
@#$#@#$#@
GRAPHICS-WINDOW
688
10
1340
111
-1
-1
13.143
1
10
1
1
1
0
1
1
1
-24
24
-3
3
1
1
1
ticks
30.0

BUTTON
16
10
102
43
NIL
setup-line
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
108
48
195
116
n-peds
0.0
1
0
Number

BUTTON
15
48
103
81
NIL
go-parallel
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
107
11
295
44
time-for-it
time-for-it
500
5000
0.0
500
1
NIL
HORIZONTAL

SWITCH
396
12
486
45
fundDiag
fundDiag
0
1
-1000

BUTTON
14
84
104
117
export
export-plot \"total-density-flow\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/total-density-flow\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"lane-usage\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/lane-usage\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"lane0-density-flow\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/lane0-density-flow\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"lane1-density-flow\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/lane1-density-flow\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"lane2-density-flow\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/lane2-density-flow\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"flow-laneusage\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/flow-laneusage\" ( remove \":\" date-and-time) \".csv\")\nexport-plot \"change-rate\" ( word \"C:/Users/marco/Documents/Sistemi Complessi/6_FINALE/Simulazioni/temp/change-rate\" ( remove \":\" date-and-time) \".csv\")\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
394
50
481
110
p-del
0.2
1
0
Number

INPUTBOX
200
49
293
116
lanes
2.0
1
0
Number

INPUTBOX
489
52
581
112
p-l2r
0.012
1
0
Number

PLOT
269
122
542
366
lane-usage
density
lane-usage
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"lane0" 1.0 0 -14070903 true "set-plot-pen-mode 0\n" "plotxy density lane-0-usage\n"
"lane1" 1.0 0 -955883 true "set-plot-pen-mode 0" "\nplotxy density lane-1-usage"
"lane2" 1.0 0 -10899396 true "" "plotxy density lane-2-usage"

PLOT
0
121
266
366
total-density-flow
density [ped/cell]
flow [ped/cell*tick]
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "set-plot-pen-mode 2" "plot-pen-down\nplotxy density flow\nplot-pen-up"

INPUTBOX
298
49
387
117
slow-cars
0.15
1
0
Number

PLOT
3
371
266
627
lane0-density-flow
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"flow/density0" 1.0 0 -14070903 true "set-plot-pen-mode 2" "plot-pen-down\nplotxy density-0 flow-0\nplot-pen-up"

PLOT
270
371
546
627
lane1-density-flow
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "set-plot-pen-mode 2" "plot-pen-down\nplotxy density-1 flow-1\nplot-pen-up"

SWITCH
300
11
391
44
right-ban
right-ban
0
1
-1000

INPUTBOX
586
51
672
111
voff
8.0
1
0
Number

PLOT
550
370
825
626
lane2-density-flow
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "set-plot-pen-mode 2" "plot-pen-down\nplotxy density-2 flow-2\nplot-pen-up"

PLOT
546
122
825
365
change-rate
NIL
NIL
0.0
1.0
0.0
0.1
true
false
"" ""
PENS
"ltor" 1.0 0 -2674135 true "set-plot-pen-mode 0" "plotxy density ( changes_LtoR / ( time * how-many))"
"rtol" 1.0 0 -13840069 true "set-plot-pen-mode 0" "plotxy density (changes_RtoL / ( time * how-many))"
"total" 1.0 0 -13791810 true "" "plotxy density ((changes_RtoL + changes_LtoR) / ( time * how-many))"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
