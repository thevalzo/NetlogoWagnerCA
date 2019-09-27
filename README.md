# NetlogoWagnerCA
Implementation in netlogo of the traffic Cellular Automata model described by Wagner, Nagel and Wolf in "Realistic multi-lane traffic rules for cellular automata".

The file named "Wagner" contains the original model, to be configured with slow-cars = 0.15 , p-del (randomic deceleration) = 2, p-l2r = 0.012 and voff = 8.

The first modification is to allow overtake from right, and you need only to turn off the "right-ban" switch.
The second modification is implemented in the "Wagner-custom" file, and consist in making easy to return in the right lane. The parameter are the same as for the original model, just voff became unused.
