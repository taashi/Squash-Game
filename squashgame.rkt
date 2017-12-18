;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname q2) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require rackunit)
(require 2htdp/image)
(require 2htdp/universe)
(require "extras.rkt")
;;(check-location "06" "q2.rkt")


(provide
 simulation
 initial-world
 world-ready-to-serve?
 world-after-tick
 world-after-key-event
 world-after-mouse-event
 racket-after-mouse-event
 world-balls
 world-racket
 ball-x
 ball-y
 ball-vx
 ball-vy
 racket-x
 racket-y
 racket-vx
 racket-vy
 racket-selected?)


;;SIMULATION FUNCTION :

;;simulation : PosReal -> World
;;; GIVEN: the speed of the simulation, in seconds per tick
;;;(so larger numbers run slower)
;;;EFFECT: runs the simulation, starting with the initial world
;;;RETURNS: the final state of the world
;;;EXAMPLES:
;;;(simulation 1) runs in super slow motion
;;;(simulation 1/24) runs at a more realistic speed

(define (simulation speed)
  (big-bang (initial-world speed)
            (on-tick world-after-tick speed)
            (on-draw world-to-scene)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)))


;;CONSTANTS                                 
;; dimensions of the rectangle and circle
(define RACKET-WIDTH 47)
(define RACKET-HEIGHT 7)
(define BALL-RADIUS 3)
(define RACKET-HALF-WIDTH 23.5)
(define RACKET-HALF-HEIGHT 3.5)
(define BALL-RADIUS2 4)

;;features of an image (eg. solid, outline, color, etc.)
(define SOLID "solid")
(define OUTLINE "outline")
(define BLACK "black")
(define GREEN "green")
(define BLUE "blue")

;; dimensions of the canvas
(define CANVAS-WIDTH 425)
(define CANVAS-HEIGHT 649)

;; image of the empty canvas,circle,rectangle
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))
(define EMPTY-CANVAS-Y (empty-scene CANVAS-WIDTH CANVAS-HEIGHT "yellow"))
(define CIRCIMAGE
  (circle BALL-RADIUS SOLID BLACK))
(define RECTIMAGE
  (rectangle RACKET-WIDTH RACKET-HEIGHT OUTLINE GREEN))
(define POINTER
  (circle BALL-RADIUS2 SOLID BLUE))


;; initial x and y coordinates and velocities of racket and ball
(define INIT-RACKET-X 330)
(define INIT-RACKET-Y 384)
(define INIT-RACKET-VX 0)
(define INIT-RACKET-VY 0)
(define INIT-BALL-X 330)
(define INIT-BALL-Y 384)
(define INIT-BALL-VX 0)
(define INIT-BALL-VY 0)
(define READY-BALL-VX 3)
(define READY-BALL-VY -9)
(define SPEED 2)
(define INIT-PTRXD 1)
(define INIT-PTRYD 1)

;;max value of canvas
(define X-MAX 425)
(define Y-MAX 649)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS                                  


;; REPRESENTATION:

;; A World is represented as a
;;(make-world racket balls paused? ticks speed ready-to-serve? ptrx ptry)

;; INTERPRETATION:
;; racket :Racket represents the racket in world
;;balls :Balls represents the list of balls in world
;; paused? :Boolean describes whether or not the world is paused
;; ticks : PosReal represents the number of ticks when speed is
;; given as above
;;;; speed: PosReal represents the speed of the simulation,
;; in seconds per tick
;; (so larger numbers run slower)
;; ready-to-serve? : Boolean represents whether or not the world is in
;; its ready-to-serve state
;;ptrx : Integer represents the x coordinate of the blue pointer in pixels
;;ptry : Integer represents the y coordinate of the blue pointer in pixels

;; IMPLEMENTATION:
(define-struct world (racket balls paused? ticks
                             speed ready-to-serve? ptrx ptry))

;; CONSTRUCTOR TEMPLATE:
;; (make-world Racket Balls Boolean PosReal PosReal Boolean Int Int)

;; OBSERVER TEMPLATE:
;; world-fn : World -> ??
(define (world-fn w)
  (... (world-racket w)
       (world-balls w)
       (world-paused? w)
       (world-ticks w)
       (world-speed w)
       (world-ready-to-serve?)
       (world-ptrx w)
       (world-ptry w)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;RACKET
;; REPRESENTATION:
;; A Racket is represented as
;;(make-racket x y vx vy selected? ptrxd ptryd) 

;; INTERPRETATION:
;;x : Integer represents
;;x coordinate of the center of the racket in pixels
;;y : Integer represents
;;y coordinate of the center of the racket in pixels
;;vx : Integer represents the velocity of the racket in X-direction in pixels
;;vy : Integer represents the velocity of the racket in Y-direction in pixels
;; selected?  : Boolean represents whether or not the Racket is selected
;;ptrxd: Integer is the distance of the x-coordinate 
;; of the pointer with the center of the Racket in pixels
; ptryd: Integer is  the distance of the y-coordinate 
;;  of the pointer with the center of the Racket in pixels



;; IMPLEMENTATION
(define-struct racket( x y vx vy selected? ptrxd ptryd))

;; CONSTRUCTOR TEMPLATE:
;;(make-racket Integer Integer Integer Integer Boolean Integer Integer)

;; OBSERVER TEMPLATE:
;; template:
;; racket-fn : Racket -> ??
(define (racket-fn r)
  (... (racket-x r)
       (racket-y r) 
       (racket-vx r)
       (racket-vy r)
       (racket-selected?)
       (racket-ptrxd)
       (racket-ptryd)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; REPRESENTATION:
;; A Ball is represented as (make-ball x y vx vy)
;; INTERPRETATION:
;; x:Integer represents the x coordinate of the center of the ball
;;in pixels
;; y:Integer  represents the y coordinate of the center of the ball
;;in pixels
;;vx:Integer  represents the velocity of the ball in X-direction
;;in pixels
;;vy: Integer  represents the velocity of the ball in Y-direction
;;in pixels

;;Balls is a list of ball.

;; IMPLEMENTATION
(define-struct ball (x y vx vy))

;;CONSTRUCTOR TEMPLATE:
;(make-ball x y vx vy)

;; CONSTRUCTOR TEMPLATE:
;; empty             -- the empty list of balls
;; (cons balls)


;; OBSERVER TEMPLATE:
;; template:
;; ball-fn : Ball -> ??
;;(define (ball-fn b)
;; (... (ball-x b)
;;      (ball-y b) 
;;      (ball-vx b)
;;     (ball-vy b)))

;; OBSERVER TEMPLATE:
;; balls-fn : Balls-> ??
;;(define (ball-fn balls)
;; (cond
;;   [(empty? balls) ...]
;;   [else (... (first balls)
;;            (ball-fn (rest balls)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;initial-world : PosReal->World
;;GIVEN: the speed of the simulation, in seconds per tick
;;;     (so larger numbers run slower)
;;; RETURNS: the ready-to-serve state of the world
;;; EXAMPLE: (initial-world 1) ->
;;(make-world (make-racket 330 384 0 0 false 1 1)
;;(list(make-ball 330 384 0 0) #false 0 1 #true 0 0)
;; STRATEGY: Use constructor template of w

(define (initial-world sp)
  (make-world
   (make-racket INIT-RACKET-X INIT-RACKET-Y
                INIT-RACKET-VX INIT-RACKET-VY false INIT-PTRXD INIT-PTRYD)
   (cons (make-ball INIT-BALL-X INIT-BALL-Y
                    INIT-BALL-VX INIT-BALL-VY) empty)
   false 0 sp true 0 0))

;;FUNCTION FOR TEST
(define TEST-WORLD
  (make-world(make-racket 330 384 0 0 false 1 1)
             (list(make-ball 330 384 0 0))false 0
             SPEED true 0 0))
;;TESTS
(begin-for-test
  (check-equal?(initial-world 2)TEST-WORLD
               "Returns a world with a list of balls
 and racket at 330,384 with their initial
velocities as 0,0"))


;;; world-ready-to-serve? : World -> Boolean
;;; GIVEN: a world
;;; RETURNS: true iff the world is in its ready-to-serve state
;;EXAMPLES:Refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(world-ready-to-serve? TEST-WORLD)true
               "the world should be in ready-to-serve state"))

;;; world-ticks : World -> PosReal
;;; GIVEN: a world
;;; RETURNS: the current tick
;;EXAMPLES: Refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(world-ticks TEST-WORLD)0
               "the current tick should be zero"))
;;; world-speed : World -> PosReal
;;; GIVEN: a world
;;; RETURNS: the current speed of the simulation
;;EXAMPLES: Refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(world-speed TEST-WORLD)2
               "the speed should be two"))
;;; world-paused? : World -> Boolean
;;; GIVEN: a world
;;; RETURNS: a boolean value indicating if the world is paused or not
;;EXAMPLES: refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS: 
(begin-for-test
  (check-equal?(world-paused? TEST-WORLD)false
               "false should be returned"))
;;; world-ptrx : World -> Int
;;; GIVEN: a world
;;; RETURNS: the pointer's x position in pixels
;;EXAMPLES: refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(world-ptrx TEST-WORLD)0
               "the x coordinate sohuld be 0"))
;;; world-ptry : World -> Int
;;; GIVEN: a world
;;; RETURNS: the pointer's y position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(world-ptry TEST-WORLD)0
               "the y coordinate should be 0"))
;;; ball-x : Ball -> Int
;;; GIVEN: a ball
;;; RETURNS: the ball's x position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(define BT(make-ball 20  9 5 4))
(begin-for-test
  (check-equal?(ball-x BT)20
               "the x coordinate should be 20"))
;;; ball-y : Ball -> Int
;;; GIVEN: a ball
;;; RETURNS: the ball's y position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
;(define BT(make-ball 20  9 5 4))
(begin-for-test
  (check-equal?(ball-y BT)9
               "the y coordinate should be 9"))
;;; ball-vx : Ball -> Int
;;; GIVEN: a ball
;;; RETURNS: the ball's vx position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
;(define BT(make-ball 20  9 5 4))
(begin-for-test
  (check-equal?(ball-vx BT)5
               "the y coordinate should be 5"))
;;; ball-vy : Ball -> Int
;;; GIVEN: a ball
;;; RETURNS: the ball's vy position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
;(define BT(make-ball 20  9 5 4))
(begin-for-test
  (check-equal?(ball-vy BT)4
               "the y coordinate should be 4"))
;;; racket-x : Racket -> Int
;;; GIVEN: a racket
;;; RETURNS: the racket's x position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(define RT(make-racket 20  9 5 4 true 0 0))
(begin-for-test
  (check-equal?(racket-x RT)20
               "the x coordinate should be 20"))
;;; racket-y : Racket-> Int
;;; GIVEN: a racket
;;; RETURNS: the racket's y position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:
(begin-for-test
  (check-equal?(racket-y RT)9
               "the y coordinate should be 9"))
;;; racket-vx : Racket -> Int
;;; GIVEN: a racket
;;; RETURNS: the racket's vx position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:

(begin-for-test
  (check-equal?(racket-vx RT)5
               "the y coordinate should be 5"))
;;; racket-vy : Racket -> Int
;;; GIVEN:a racket
;;; RETURNS: the racket's vy position in pixels
;;EXAMPLES:refer tests
;;FUNCTION DEFINTION : This function is created using the world struct
;;TESTS:

(begin-for-test
  (check-equal?(racket-vy RT)4
               "the y coordinate should be 4"))



;;DRAWING METHODS                          

;;CONTRACT:
;; world-to-scene : World -> Scene
;;GIVEN          : the given world
;;RETURNS        : a Scene that portrays the given world
;;EXAMPLE:
;; (world-to-scene TEST-WORLD)
;;     => a canvas with a Racket at (330,384) and a Ball at (330,384)
;;;; STRATEGY: Use observer template of w
(define (world-to-scene w)
  (place-racket
   (world-racket w)
   (scene-with-ball
    (world-balls w)
    (select-canvas w))w))

;; FUNCTIOND FOR TESTS
(define scene-TEST-WORLD
  (place-image RECTIMAGE INIT-RACKET-X INIT-RACKET-Y
               (place-image CIRCIMAGE INIT-BALL-X INIT-BALL-Y EMPTY-CANVAS)))
;;TESTS
(begin-for-test
  (check-equal?(world-to-scene TEST-WORLD)scene-TEST-WORLD
               "a canvas with a Racket at (330,384) and a Ball at (330,384)"))
;;select-canvas: World->Scene
;;GIVEN : A world
;;RETURNS:A canvas with background color yellow or white
;;EXAMPLES :See tests
;;STRATEGY : Cases on if the world is paused or not
;;FUNCTION DEFINITION
(define (select-canvas w)
  (if
   (world-paused? w)
   EMPTY-CANVAS-Y
   EMPTY-CANVAS))
;;FUNCTIOND FOR TESTS
(define WORLDSAMPLE2(make-world
                     (make-racket 333 401 50 60 false 0 0)
                     (list(make-ball 20  9 5 4))false 1 25 false 0 0))
(define WORLDSAMPLE3(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))true 1 25 false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(select-canvas WORLDSAMPLE2)EMPTY-CANVAS"white canvas")
  (check-equal?(select-canvas WORLDSAMPLE3)EMPTY-CANVAS-Y)"yellow canvas")
;;rectimage:Racket->Image of thegreen racket
;;GIVEN:Racket
;;RETURNS: Image of the green racket
;;STRATEGY: use simpler fns
;;EXAMPLES:(rectimage(make-racket 333 401 50 60 false 0 0))->RECTIMAGE
(define (rectimage c)
  (rectangle RACKET-WIDTH RACKET-HEIGHT OUTLINE GREEN))
;;TESTS:Covered with other test cases

;; racket-with-pointer: Scene Int Int-> Scene
;;GIVEN           : Scene and Coordinates of the pointer
;;RETURNS         : a Scene, same as the given one, but with the  
;;                  pointer and racket
;;EXAMPLES:
;; (place-image POINTER 200 300 EMPTY-CANVAS)
;;    => a canvas with a Ball at (200,300) 
   
;;DESIGN STRATEGY :  Use simpler fns


(define (racket-with-pointer scene ptrx ptry)
  (place-image POINTER ptrx ptry scene))

;;FUNCTIONS FOR TESTS
(define IMAGESAMPLE2
  (place-image POINTER
               200 300 EMPTY-CANVAS))
;; TESTS
(begin-for-test
  (check-equal?(racket-with-pointer EMPTY-CANVAS 200 300)
               IMAGESAMPLE2"the pointer
should be returned at 200,300"))

;;scene-with-racket: Racket Scene->Scene
;;GIVEN: Racket and scene
;;RETURNS : A racket image on the scene as per the coordinates mentioned
;;EXAMPLES:Refer tests
;;DESIGN-STRATEGY: Use simpler fns
(define (scene-with-racket c scene)
  (place-image
   (rectimage c)
   (racket-x c) (racket-y c)
   scene))
;;TESTS:
(define TESTFORSCENERACKET
  (scene-with-racket(make-racket 333 401 50 60 false 0 0)
                    (empty-scene 425 649)))
(define RACKETTEST(make-racket 333 401 50 60 false 0 0))
(begin-for-test
  (check-equal?(scene-with-racket RACKETTEST EMPTY-CANVAS)TESTFORSCENERACKET)
  "Canvas with racket at (330,384)")



;; place-racket  : Racket Scene -> Scene
;;GIVEN          : a Racket and a Scene
;;RETURNS        : a Scene, same as the given one, but with the given Racket 
;;                 placed on it
;;EXAMPLES:
;; (place-image(make-racket 333 401 3 40 false 0 0) EMPTY-CANVAS)
;;    => a canvas with a Racket at (333,401)
;;DESIGN STRATEGY : Divide into conditions on whether racket is selected
(define (place-racket ra scene w)
  (cond
    [(racket-selected? ra)
     (racket-with-pointer  (scene-with-racket ra scene) (world-ptrx w)
                           (world-ptry w))]
    [else(scene-with-racket ra scene)]))
;;FUNCTIONS FOR TESTS
(define RSAMPLE(make-racket 333 401 3 40 false 0 0))
(define RSAMPLETR(make-racket 333 401 3 40 true 330 384))
(define WORLDSAMPLE(make-world(make-racket 333 401 50 60 false 0 0)
                              (list(make-ball 20  9 5 4))false 1 25 false 0 0))
(define WORLDSAMPLE8(make-world(make-racket 333 401 50 60 true 0 0)
                               (list(make-ball 20  9 5 4))
                               false 1 25 false 100 200))
(define IMAGESAMPLE(place-image RECTIMAGE 333 401 EMPTY-CANVAS))
(define TESTER(place-image RECTIMAGE 333 401
                           (place-image POINTER 100 200 EMPTY-CANVAS)))

;;TESTS
(begin-for-test
  (check-equal? (place-racket RSAMPLETR EMPTY-CANVAS WORLDSAMPLE8)TESTER)
  "A canvas
;;with a racket at 333,401")


;; racket-selected ? : Racket ->Boolean
;;GIVEN          : a Racket 
;;RETURNS        : a Boolean true or false if the racket is selected
;;EXAMPLES:
;; (racket-selected? RSAMPLE)->false
;;DESIGN STRATEGY:Divide into conditions on racket-selected
;;TESTS:
(begin-for-test (check-equal?(racket-selected? RSAMPLE)
                             false"false should be returned")
                (check-equal?(racket-selected? RSAMPLETR)
                             true"true should be returned") )

;;CONTRACT:
;; scene-with-ball    : Balls Scene -> Scene
;;GIVEN           : a Ball and a Scene
;;RETURNS         : a Scene, same as the given one, but with the given Ball 
;;                  placed on it
;;EXAMPLES:
;; (place-image (make-ball 200 200 1 4) EMPTY-CANVAS)
;;    => a canvas with a Ball at (200,200) 
   
;;DESIGN STRATEGY : use template of Ball on b

(define (scene-with-ball blist scene)
  (place-images
   (listofballs blist)
   (listofcords blist)
   scene))
;;TESTS: 
(define BLST(list(make-ball 330 384 3 -9)(make-ball 330 384 3 -9)))
(define IMAGESAMPLEl(place-image CIRCIMAGE 330 384 EMPTY-CANVAS))

;;listofballs : BallList->BallList
;;GIVEN : BallList
;;RETURNS: A ballList
;;STRATEGY : Use HOF  map on BallList
;;(define(listofballs lst1)
;;(cond
;;[(empty? lst1) empty]
;;[else(cons (circimage(first lst1))
;;         (listofballs (rest lst1)))]))
#|(define(listofballs lst1)
  (cond
    [(empty? lst1) empty]
    [else (map circimage lst1)]))|#

(define(listofballs lst1)
 (foldr (lambda (x r)(cons(circimage x)r))'() lst1))
;;TESTS:
(begin-for-test
  (check-equal? (listofballs '())'()))

;;listofcoordinates : BallList->BallList
;;GIVEN : BallList
;;RETURNS:BallList
;;STRATEGY :Use HOF map on BallListList         
#|(define(listofcords  lst2)
  (cond
    [(empty? lst2) empty]
    [else
     (cons
      (make-posn( ball-x(first lst2))(ball-y(first lst2)))
      (listofcords(rest lst2)))]))|#

#|(define(listofcords  lst2)
  (cond
    [(empty? lst2) empty]
    [else
     (map cords lst2)]))|#
(define(listofcords lst2)
 (foldr (lambda (x r)(cons(cords x)r))'() lst2))
;;TESTS:
(begin-for-test
  (check-equal? (listofcords'())'()))
;;cords: Ball->Coordinates
;;GIVEN: Ball
;;RETURNS: Coordinates
;;STRATEGY: Use template of list on coordinates
;;EXAMPLES:(cords(make-ball 10 20 30 40))->(make-posn 10 20)
(define (cords at)
  (make-posn(ball-x  at)(ball-y  at)))
;;TESTS:
(begin-for-test
  (check-equal?(cords(make-ball 10 20 30 40))
               (make-posn 10 20)))
;;circimage:Ball->Image of the black ball
;;GIVEN:Ball
;;RETURNS: Image of the black ball
;;STRATEGY: Use simpler fns
;;EXAMPLES:(circimage (make-ball 20 0 40 20))->CIRCIMAGE 

(define (circimage d)
  (circle BALL-RADIUS SOLID BLACK))
;;TESTS:
(define test
  (place-images
   (list CIRCIMAGE
         CIRCIMAGE)
        
   (list (make-posn 330 384)
         (make-posn 330 384)
         )
   EMPTY-CANVAS))

(begin-for-test
  (check-equal?(scene-with-ball BLST EMPTY-CANVAS) test))
               

  

;; MOUSE EVENT HANDLING                                  

;;; world-after-mouse-event:

;;CONTRACT:
;; world-after-mouse-event: World Int Int MouseEvent -> World
;;GIVEN      : a World, the x and y coordinates of a mouse event,
;;                      and the mouse event
;;RETURNS    : the World that should follow the given world after
;;             the given mouse event
;;EXAMPLES:
;Refer tests
;;DESIGN STRATEGY: use constructor template of World on w
;;FUNCTION DEFINITION:


(define (world-after-mouse-event w mx my mev)
  (if
   (not(or(world-paused? w)(world-ready-to-serve? w)))
   (make-world
    (racket-after-mouse-event (world-racket w) mx my mev)
    (world-balls w )(world-paused? w) (world-ticks w)
    (world-speed w) (world-ready-to-serve? w)
    mx my)
   w))
;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS FOR TESTS
(define WORLDSAMPLE4(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))
                               false 1 25 false 0 0))
(define WORLDSAMPLE7(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))
                               true 1 25 false 0 0))
(define WORLDTEST(make-world (make-racket 333 401 50 60 #false 0 0)
                             (list (make-ball 20 9 5 4))
                             #false 1 25 #false 100 150))
;;TESTS
(begin-for-test
  (check-equal?(world-after-mouse-event WORLDSAMPLE4 100 150 "drag")
               WORLDTEST)
  (check-equal?(world-after-mouse-event WORLDSAMPLE7 100 150 "drag")
               WORLDSAMPLE7))
               
;;; racket-after-mouse-event
;;;     : Racket Int Int MouseEvent -> Racket
;;; GIVEN: a racket, the x and y coordinates of a mouse event,
;;;     and the mouse event
;;; RETURNS: the racket as it should be after the given mouse event
;; STRATEGY:Divide into cases based on mouse event
;;EXAMPLES: Refer tests
(define (racket-after-mouse-event ra mx my mev)
  (cond
    [(mouse=? mev "button-down") (racket-after-button-down ra mx my)]
    [(mouse=? mev "drag") (racket-after-drag ra mx my)]
    [(mouse=? mev "button-up") (racket-after-button-up ra mx my)]
    [else ra]))
;;TESTS
(begin-for-test
  (check-equal?(racket-after-mouse-event RTESTER 320 350 "enter")
               RTESTER))
 
;; racket-after-button-down : racket Integer Integer -> racket
;; GIVEN: racket, curren mouse co-ordinates 
;; RETURNS: The racket that should follow the current racket after mouse
;;          button down event
;; EXAMPLES: See tests
;; STRATEGY:Use constructor template for racket on rak
(define (racket-after-button-down ra mx my)
  (if (in-racket? ra mx my)
      (make-racket (racket-x ra) (racket-y ra)
                   (racket-vx ra) (racket-vy ra) true
                   (dist-ptrxd (racket-x ra) mx)
                   (dist-ptryd (racket-y ra) my))
      ra))

;;TESTS
(begin-for-test
  (check-equal?(racket-after-button-down RTESTER 320 350)
               (make-racket 330 345 3 40 #true -10 5))
  (check-equal?(racket-after-button-down RSAMPLETR 380 378)RSAMPLETR))
;; racket-after-drag : racket Integer Integer -> racket
;; GIVEN: a racket, current co-ordinates of mouse
;; RETURNS: the racket following a drag at the given location
;; EXAMPLES: See tests
;; STRATEGY: Use constructor template for racket on rak
(define (racket-after-drag ra mx my)
  (if (racket-selected? ra)
      (make-racket (- mx (racket-ptrxd ra))
                   (- my (racket-ptryd ra)) (racket-vx ra) (racket-vy ra)
                   true (racket-ptrxd ra) (racket-ptryd ra))
      ra))
;;TESTS:
(begin-for-test
  (check-equal?(racket-after-drag RTESTER 320 350)
               (make-racket -10 -34 3 40 #true 330 384)))

;; racket-after-button-up : racket Integer Integer -> racket
;;GIVEN: racket, x coordinate of the mouse, y coordinate of the mouse
;; RETURNS: the racket following a button-up at the given location
;; STRATEGY: Use constructor template for racket on rak
;;EXAMPLES: Refer tests
(define (racket-after-button-up ra mx my)
  (if (racket-selected? ra)
      (make-racket  (racket-x ra) (racket-y ra)
                    (racket-vx ra) (racket-vy ra)  false
                    (racket-ptrxd ra) (racket-ptryd ra))
      ra))
;;TESTS:
(begin-for-test
  (check-equal?(racket-after-button-up RTESTER 320 350)
               (make-racket 330 345 3 40 #false 330 384))
  (check-equal?(racket-after-button-up RSAMPLE 320 350)
               RSAMPLE  ))

;; in-racket? : racket Integer Integer -> racket
;; GIVEN: a racket and co-ordinates of a point
;; RETURNS true iff the given coordinate is inside the bounding box of
;; the given racket.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases on racket's coordinates
(define (in-racket? ra x y)
  (and
   (and(>= (+ (racket-x ra) 25)x)
       (<=(- (racket-x ra) 25)x))
   (and (<= (- (racket-y ra) 25)y)
        (>= (+ (racket-y ra) 25)y))))
;;FUNCTIONS FORT TESTS
(define RTESTER(make-racket 330 345 3 40 true 330 384))
;;TESTS
(begin-for-test
  (check-equal?(in-racket? RSAMPLETR 380 378)
               #false)
  (check-equal?(in-racket? RTESTER 320 350)
               #true) )

;; dist-ptrxd: Integer Integer -> Integer 
;; GIVEN: current x co-ordinate of racket center and x-coordinate of
;;        mouse pointer
;; RETURNS: Distance between x-cordinate of center of racket and
;;        clicked location
;; STRATEGY: Combine simpler functions
(define (dist-ptrxd x mx)
  (- mx x)
  )

;; dist-ptryd: Integer Integer -> Integer
;; GIVEN: current y co-ordinate of racket center and y-coordinate of
;;        mouse pointer
;; RETURNS: Distance between y-cordinate of center of racket and
;;        clicked location
;; STRATEGY: Combine simpler functions
(define (dist-ptryd y my)
  (- my y)
  )

;;TESTS
(begin-for-test
  (check-equal?(racket-after-mouse-event RTESTER 320 350 "button-down")
               (make-racket 330 345 3 40 #true -10 5))
  (check-equal?  (racket-after-mouse-event RTESTER 320 350 "button-up")
                 (make-racket 330 345 3 40 #false 330 384)))
  
;; AFTER TICK HANDLER                            
;;;world-after-tick:

;;CONTRACT:
;;; world-after-tick : World -> World
;;GIVEN: any world that's possible for the simulation with speed s
;;RETURNS: the world that should follow the given world
;;         after a tick
;;EXAMPLES:(world-after-tick (make-world(make-racket 330 384 0 0 false 0 0)
;; (list(make-ball 330 384 3 -9)false 1 25 true 0 0))->
;;(make-world (make-racket 330 384 0 0 #false 0 0)
;;(list (make-ball 333 375 3 -9)) #false 1 25 #true 0 0)
;;(world-after-tick (make-world(make-racket 330 384 0 0)
;;(make-ball 330 384 3 -9)false 1 25 false))->
;;(make-world (make-racket 330 384 0 0) (make-ball 333 375 3 -9)
;;#false 1 25 #false)
;;;;DESIGN STRATEGY: Divide into conditions on w

(define (world-after-tick w)
  ( cond
     [(world-paused? w)(paused-world w)]
     [(empty? (world-balls w)) (pause-world w) ]
     [(<= (+ (racket-y (world-racket w)) (racket-vy (world-racket w))) 0)
      (pause-world w)]
     [(validate-collision?  (world-balls w)(world-racket w))
      (change-in-velocity w)]
     [(racket-selected? (world-racket w)) (make-world
                                           (world-racket w)
                                           (ball-after-tick  (world-balls w))
                                           (world-paused? w)
                                           (world-ticks w)
                                           (world-speed w)
                                           (world-ready-to-serve? w)
                                           (world-ptrx w)
                                           (world-ptry w))]
     [else
      (make-world
       (racket-after-tick (world-racket w))
       (ball-after-tick  (world-balls w))
       (world-paused? w)
       (world-ticks w)
       (world-speed w)
       (world-ready-to-serve? w)
       0
       0)]))
;;FUNCTIONS FOR TESTS
(define WS(make-world(make-racket 330 384 0 0 false 0 0)
                     (list(make-ball 330 384 3 -9))false 1 25 true 0 0))
(define BE(make-world(make-racket 330 384 0 0 false 0 0)
                     (list)false 1 25 false 0 0))
(define BEA(make-world(make-racket 330 384 0 0 false 0 0)
                      (list)true 1 25 false 0 0))
(define WPA(make-world(make-racket 330 384 0 0 false 0 0)
                      (list(make-ball 330 384 3 -9))true 2 25 false 0 0))
(define WP(make-world(make-racket 330 384 0 0 false 0 0)
                     (list(make-ball 330 384 3 -9))true 1 25 false 0 0))
(define WSA(make-world (make-racket 330 384 0 0 #f 0 0)
                       (list (make-ball 333 375 3 -9)) #f 1 25 #t 0 0))
(define WR(make-world(make-racket 330 -384 0 0 false 0 0)
                     (list(make-ball 330 384 3 -9))false 1 25 false 0 0))
(define WRA(make-world (make-racket 330 -384 0 0 #false 0 0)
                       (list (make-ball 330 384 3 -9))
                       #true 1 25 #false 0 0))
(define WCOLL(make-world(make-racket 300 400 2 3 false 0 0 )
                        (list(make-ball 300 390 3 20 )
                             (make-ball 300 400 3 20 ))false
                                                       1 24 false 0 0))
(define WCOLLA (make-world
                (make-racket 300 400 2 3 #f 0 0)
                (list (make-ball 300 390 3 -17) (make-ball 300 400 3 20))
                #f 1 24 #f 0 0))
(define WORLDSAMPLERT(make-world(make-racket 333 401 50 60 true 20 30)
                                (list(make-ball 20  9 5 4))
                                false 1 25 false 0 0))
(define WORLDSAMPLERTA (make-world
                        (make-racket 333 401 50 60 #t 20 30)
                        (list (make-ball 25 13 5 4)) #f 1 25 #f 0 0))
;;TESTS
(begin-for-test
  (check-equal?(world-after-tick WS)WSA)
  (check-equal?(world-after-tick WP)WPA)
  
  (check-equal?(world-after-tick BE)BEA)
  (check-equal?(world-after-tick WR)WRA)
  (check-equal?(world-after-tick WCOLL)WCOLLA)
  (check-equal? (world-after-tick WORLDSAMPLERT)WORLDSAMPLERTA))


;;;validate-collision: 

;;CONTRACT:
;;; validate-collision : BallList Racket -> boolean
;;GIVEN: A balllist and a racket
;;RETURNS:a Boolean value to check for collision
;;EXAMPLES:(validate-collision? RSSAMPLE SQUASHBALLLIST)->false
;;STRATEGY: Use HOF and ormap on BallList
#|(define (validate-collision? squashballlist racket_state)
(cond
[(empty? squashballlist) false]
[else(or(ball-after-collision-with-racket?
 (first squashballlist)  racket_state)
(validate-collision? (rest squashballlist)racket_state))]))|#
(define (validate-collision? squashballlist racket_state)
  (cond
    [(empty? squashballlist) false]
    [else
     (ormap
      ;;Ball->Boolean
      ;;GIVEN: Ball
      ;;RETURNS: true if the ball and racket collides
      (lambda (b)
        (ball-after-collision-with-racket? b racket_state))
      squashballlist)]))
;;FUNCTIONS FOR TESTS
(define RSSAMPLE(make-racket 333 401 3 -4 true 0 0))
(define SQUASHBALLLIST(list(make-ball 330 384 3 -9)))
(define EMPTYSAMPLELIST '())
;;TESTS:
(begin-for-test
  (check-equal?(validate-collision? EMPTYSAMPLELIST RSSAMPLE)
               false "f should be returned"))

;;;change-in-velocity: 

;;CONTRACT:
;;; change-in-velocity : World->World
;;GIVEN: A World
;;RETURNS:a World with the list of balls
;;with the change in velocityafter colliding
;;with racket
;;EXAMPLES:see tests
;;DESIGN STRATEGY: use constructor template of w 
;;FUNCTION DEFINTION:
(define(change-in-velocity w)
  (make-world
   (make-racket(racket-x (world-racket w))
               (racket-y (world-racket w))(racket-vx (world-racket w))
               (new-vy (world-racket w))(racket-selected? (world-racket w))
               (racket-ptrxd (world-racket w))
               (racket-ptryd (world-racket w)))
   (makingballlist (world-balls w) (world-racket w))
   (world-paused? w) (world-ticks w) (world-speed w)
   (world-ready-to-serve? w) (world-ptrx w) (world-ptry w) ))
;;TESTS:
(define WV(make-world(make-racket 330 384 10 20 false 0 0)
                     (list(make-ball 330 384 3 -9))false 1 25 true 0 0))
(begin-for-test
  (check-equal? (change-in-velocity WV)WV))
;;(change-in-velocity 
;;; makingballlist:  

;;CONTRACT:
;; makingballlist:  BallList racket -> BallList racket
;;GIVEN      :BallList racket
;;RETURNS    : the list of balls with their new 'x' 'y' positions
;;             new x-velocity y-velocity after each
;;ball collides with the racket.
;;EXAMPLES:(makingballlist BLST RSAMPLETR)
;(list (make-ball 330 384 3 -9) (make-ball 330 384 3 -9))
;;DESIGN STRATEGY: Use HOF map and lambda on ball
;;FUNCTION DEFINITION:
#|(define(makingballlist lst rakt)
  (cond
 [(empty? lst) null]
 [(ball-after-collision-with-racket?(first lst) rakt)
  (cons(make-ball(ball-x (first lst))
 (ball-y (first lst))(ball-vx (first lst))
  (-(racket-vy rakt)(ball-vy (first lst))))
(makingballlist(rest lst)rakt))]
 [else (cons (first lst) (makingballlist (rest lst) rakt))]))|#

(define(makingballlist b rak)
  (map
   ; Ball Racket->Ball
   ;;GIVEN: Racket
   ;;RETUNRS: Ball with updated velocities if it collides with racket
   (lambda(b)(if(ball-after-collision-with-racket? b rak)
                (make-ball(ball-x  b)
                          (ball-y b)(ball-vx b)
                          (-(racket-vy rak)(ball-vy b)))
                b))b))
                                    
;;TESTS
;;(define BSAMPLEli(list(make-ball 300 390 3 20 )(make-ball 300 400 3 20 )))
;;(define RAKSAMPLE(make-racket 300 400 2 3 false 0 0 ))
;;(begin-for-test
;;(check-equal?(makingballlist BLST RSAMPLETR)
;;(list (make-ball 330 384 3 -9) (make-ball 330 384 3 -9)))
;; (check-equal? (makingballlist BSAMPLEli RAKSAMPLE)
;;(list (make-ball 300 390 3 -17) (make-ball 300 400 3 -17))))
;; (check-equal(makingballlist b)
;; new-raket-y-velocity
;;(begin-for-test
;  (check-equal?(maker (make-ball 10 20 30 40)RSAMPLETR)
;(make-ball 10 20 30 0)))

;;CONTRACT:
;; new-raket-y-velocity Racket -> Real
;;GIVEN      :Racket
;;RETURNS    : the new velocity of racket after an
;;individual ball collides with the racket.
;;EXAMPLES:(new-vy RSAMPLETR)
;->40
;;STRATEGY: use cases on racket-vy
(define(new-vy rac)
  (if (<(racket-vy rac)0)0(racket-vy rac)))
;;TESTS
(define RSAMPLETRA(make-racket 333 401 3 -40 true 0 0))
(begin-for-test
  (check-equal?(new-vy RSAMPLETR)
               40)
  (check-equal?(new-vy RSAMPLETRA)
               0))
  
;;; ball-after-collision-with-racket? BallList Racket

;;CONTRACT:
;; ball-after-collision-with-racket? BallList Racket -> Boolean
;;GIVEN      :BallList Racket
;;RETURNS    : true if the ball has collided with racket
;;EXAMPLES:(ball-after-collision-with-racket? BSAMPLE RAKSAMPLE)
;;->true
;;DESIGN STRATEGY : Divide
;into Conditions on the positions of the racket and the ball
;;to determine if collision occurs
(define (ball-after-collision-with-racket? squashball squashracket)
  (and
   (check-condition1? squashball squashracket)
   (and
    (check-condition2? squashball squashracket)
    (check-condition3? squashball squashracket))
   (>=(ball-vy squashball)0)))


;;CONTRACT:
;; (check-condition1? BallList Racket) -> Boolean 
;;GIVEN      :BallList Racket
;;RETURNS    : true if the ball has collided with racket
;;DESIGN STRATEGY :Divide into
;;Conditions on the positions of the racket and the ball
;;EXAMPLES: Check tests
  
(define (check-condition1? squashball squashracket)
  (not(and
       (equal? (ball-y squashball)(racket-y squashracket))
       (<= (- (racket-x squashracket)  RACKET-HALF-WIDTH)
           (ball-x squashball)(+ (racket-x squashracket)
                                 RACKET-HALF-WIDTH)))))


;;CONTRACT:
;; (check-condition2? BallList Racket) -> Boolean
;;GIVEN      :BallList Racket
;;RETURNS    : true if the ball has collided with racket
;;DESIGN STRATEGY : Divide into
;Conditions on the positions of the racket and the ball
;;EXAMPLES: Check tests
(define (check-condition2? squashball squashracket)
  (and
   ( <= (- (newposr-x squashracket)  RACKET-HALF-WIDTH)(ball-x squashball)
        (+ (newposr-x squashracket)  RACKET-HALF-WIDTH))

   ( <= (- (newposr-x squashracket)  RACKET-HALF-WIDTH)(newpos-x squashball)
        (+ (newposr-x squashracket)  RACKET-HALF-WIDTH))))


;;CONTRACT:
;; (check-condition3? BallList Racket) -> Boolean
;;GIVEN      :BallList Racket
;;RETURNS    : true if the ball has collided with racket
;;DESIGN STRATEGY :Divide into
;Conditions on the positions of the racket and the ball
;;EXAMPLES: Check tests
(define (check-condition3? squashball squashracket)
  (<=(ball-y squashball)(newposr-y squashracket)(newpos-y squashball)))
 
;;FUNCTIONS FOR TESTS
(define BSAMPLE(make-ball 328 383 3 4 ))
(define BSAMPLE1(make-ball 328 383 3 4 ))
(define RAKSAMPLE1(make-racket 330 390 0 0 false 0 0 ))
(define RAKSAMPLE(make-racket 330 384 0 0 false 0 0 ))
(define BSAMPLE12(make-ball 356 390 3 20 ))
;TESTS
(begin-for-test
  (check-equal?(ball-after-collision-with-racket? BSAMPLE RAKSAMPLE )true)
  (check-equal?(ball-after-collision-with-racket? BSAMPLE12 RAKSAMPLE1)false))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;CONTRACT:world-spacebar:World->World
 

;;GIVEN      :World
;;RETURNS    : World
;;EXAMPLES:(world-spacebar WORLDSAMPLE9)
;;-> WORLDSAMPLE9)
;;DESIGN STRATEGY : DIVIDE INTO
;Cases on the tentative position of racket's y position
 
(define (world-spacebar w)
  (cond
    [(<=  (newposr-y (world-racket w)) 0)
     (pause-world w)]
    [else w]))

;;FUNCTIONS FOR TESTS:
(define WORLDSAMPLEB(make-world(make-racket 333 -401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))


                               false 1 25 false 0 0))
;;TESTS
(begin-for-test
  (check-equal?
   (world-spacebar WORLDSAMPLEB)
   (make-world (make-racket 333 -401 50 60 #false 0 0)
               (list (make-ball 20 9 5 4)) #true 1 25 #false 0 0)
   (check-equal?
    (world-spacebar WORLDSAMPLE9)
    WORLDSAMPLE9)))




;;CONTRACT:
;;; paused-world : World -> World
;;GIVEN: any world 
;;RETURNS: the world that should follow the given world
;;         after a tick if the world is paused
;;EXAMPLES:(paused-world(make-world(make-racket 330 384 0 0)
;;(make-ball 330 384 3 -9)false 1 25 true))->
;;(make-world (make-racket 330 384 0 0)
;;(make-ball 330 384 3 -9) #false 2 25 #true)
;;(paused-world(make-world(make-racket 330 384 0 0)
;;(make-ball 330 384 3 -9)false 1 3 true))
;;(make-world (make-racket 330 384 0 0)
;;(make-ball 330 384 0 0) #false 0 3 #true)
;;;;DESIGN STRATEGY: use constructor template of World on w
(define (paused-world w)
  (if
   (= (* (world-ticks w)(world-speed w)) 3)
   (initial-world (world-speed w))
   (make-world
    (world-racket w)(world-balls w)(world-paused? w)
    (+ (world-ticks w) 1) (world-speed w)(world-ready-to-serve? w) 
    0 0 )))

;;TESTS
(begin-for-test
  (check-equal?(paused-world(make-world(make-racket 330 384 0 0 false 0 0)
                                       (list(make-ball 330 384 3 -9))
                                       false 1 25 true 0 0))
               (make-world (make-racket 330 384 0 0 false 0 0)
                           (list(make-ball 330 384 3 -9))
                           #false 2 25 #true 0 0)"It should return a world
in which the ticks in incremented by 1")
  (check-equal?( paused-world(make-world(make-racket 330 389 6 9 false 0 0)
                                        (list(make-ball 330 309 3 -9))
                                        false 1 3 true 0 0))
               (make-world (make-racket 330 384 0 0 false 1  1)
                           (list(make-ball 330 384 0 0))
                           #false 0 3 #true 0 0)
               "It should return initial world"))
  

;;CONTRACT:
;;; ball-after-tick : World -> Ball
;;GIVEN: any world 
;;RETURNS: State of Ball in an unpaused world
;;    
;;EXAMPLES:(ball-after-tick(make-world(make-racket 330 384 0 0)
;;(make-ball 330 384 3 -9)false 1 25 true))
;;(make-ball 333 375 3 -9)
;;(ball-after-tick(make-world(make-racket 330 384 0 0)
;;(make-ball 330 323 -9 -9)false 1 25 true))
;;(make-ball 321 314 -9 -9)
;;;;DESIGN STRATEGY: Divide into conditions on the position of ball
#|#(define (ball-after-tick blist)
  (cond
    [(empty? blist) null] 
    [(>= (newpos-y  (first blist)) Y-MAX)
     (remove(first blist) blist)] 
    [else

     (cons (make-ball
            (check-ball-x (first blist))
            (check-ball-y (first blist))
            (check-ball-vx (first blist))
            (check-ball-vy (first blist)))
           (ball-after-tick (rest blist)))]))|#
(define (back-wall? blist)
(not
(>= (newpos-y  blist) Y-MAX)))

(define (ball-after-tick blist)
(map ball-in-tick
     (filter back-wall? blist)))
(define(ball-in-tick blist)
  (make-ball
   (check-ball-x blist)
   (check-ball-y blist)
   (check-ball-vx blist)
   (check-ball-vy blist)))
   



;;TESTS:
(begin-for-test
  (check-equal? (ball-after-tick EMPTYSAMPLELIST)null))


;;TESTS
(define BLST1(list(make-ball 330 684 3 -9)(make-ball 330 384 3 -9)))

(begin-for-test
  (check-equal?(ball-after-tick BLST)
               (list (make-ball 333 375 3 -9) (make-ball 333 375 3 -9)))
  (check-equal? (ball-after-tick BLST1)
                (list (make-ball 333 375 3 -9)) ))

;;CONTRACT:
;;; racket-after-tick : World -> Racket
;;GIVEN: any world 
;;RETURNS: Stateof the Racket in an unpaused world
;;EXAMPLES:(racket-after-tick(make-world(make-racket 400 400 -7 20)
;;(make-ball 330 323 -9 -9)false 1 25 false))
;;(make-racket 393 420 -7 20)
;;;;DESIGN STRATEGY: use constructor template of World on w
(define (racket-after-tick ra)
  (make-racket
   (check-racket-x ra)
   (check-racket-y ra)
   (check-racket-vx ra)
   (check-racket-vy ra)
   (racket-selected? ra)0 0))

;;TESTS
(begin-for-test
  (check-equal?(racket-after-tick RTESTER4)
               (make-racket 310 394 -20 10 #false 0 0)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;newpos-x : World -> approx x coordinate of ball
;;GIVEN: any world 
;;RETURNS: the x coordinate of the ball as per the condition
;;on the current position of the ball x coordinate
;;EXAMPLES:(newpos-x
;;(make-ball 120 300 200 249))
;;  320 
;;;;DESIGN STRATEGY: use simpler functions
(define(newpos-x b)
  (+ (ball-x  b) (ball-vx b)))

;; newpos-y : World -> tentative y coordinate of ball
;;GIVEN: any world 
;;RETURNS: the y coordinate of the ball as per the condition
;;on the current position of the ball y coordinate
;;EXAMPLES:(newpos-y
;;(make-ball 120 300 200 249))
;;  320 
;;;;DESIGN STRATEGY: use simpler functions
(define(newpos-y b)
  (+ (ball-y  b) (ball-vy  b)))

;; newposr-x : World -> tentative x coordinate of ball
;;GIVEN: any world 
;;RETURNS: the y coordinate of the racket as per the condition
;;on the current position of the racket x coordinate
;;EXAMPLES:(newposr-x(make-world(make-racket 330 384 0 0)
;;(make-ball 120 300 200 249)false 1 25 false))
;;  320 
;;;;DESIGN STRATEGY: use simpler fns
(define(newposr-x ra)
  (+ (racket-x ra) (racket-vx ra)))
;; newposr-y : World -> tentative y coordinate of ball
;;GIVEN: any world 
;;RETURNS: the y coordinate of the racket as per the condition on
;;the current position of the racket y coordinate
;;EXAMPLES:(tentative-x(make-world(make-racket 330 384 0 0)
;;(make-ball 120 300 200 249)false 1 25 false))
;;  320 
;;;;DESIGN STRATEGY: use simpler fns
(define(newposr-y ra)
  (+ (racket-y ra) (racket-vy ra)))


;; check-ball-x : World -> x coordinate of ball
;;GIVEN: any world 
;;RETURNS: the x coordinate of the ball as per the condition
;;on the current position of the ball x coordinate
;;EXAMPLES:(check-ball-x(make-world(make-racket 330 384 0 0)
;;(make-ball 120 300 200 249)false 1 25 false))
;;  320 
;;;;DESIGN STRATEGY: Divide into conditions on the
;;tentative position of x coordinate
(define (check-ball-x b)
  (cond

    ;;no wall
    [(and (> (newpos-x b) 0)
          (< (newpos-x b) X-MAX))
     (newpos-x b)]
    ;;left wall
    [(<=  (newpos-x b) 0)
     ( * -1 (newpos-x b))]
    ;;right wall
    [(>= (newpos-x b) X-MAX)
     (-  X-MAX (- (newpos-x b)  X-MAX ))]))

;;TESTS
(begin-for-test
  (check-equal?(check-ball-x(make-ball 120 300 300 349))
               420 "Initial-position of ball's x coordinate
 should be returned")
  (check-equal?(check-ball-x(make-ball 120 300 200 249))
               320 "Tentative position of ball's x coordinate
 should be returned (x+vx)")
  (check-equal?(check-ball-x(make-ball 2 300 -20 349))
               18"Tentative position of ball's x coordinate
 should be returned (-1)(x+vx)")
  (check-equal?(check-ball-x (make-ball 250 300 200 349))
               400"Tentative position of ball's x coordinate
 should be returned (850-(x+vx))"))
    
  
   
   
;; check-ball-y : World -> y coordinate of ball
;;GIVEN: any world 
;;RETURNS: the y coordinate of the ball as per the condition
;;on the current position of the ball y coordinate
;;EXAMPLES:(check-ball-y(make-world(make-racket 330 384 0 0)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        384

;;;;DESIGN STRATEGY: Divide into conditions on
;the tentative position of y coordinate

(define (check-ball-y b)
  (cond
    ;;no wall
    [ (> (newpos-y b) 0)
      (newpos-y b)]
    ;;front wall
    [(<= (newpos-y b) 0)
     (* -1 (newpos-y b))]
    ))

;;TESTS
(begin-for-test
  (check-equal?(check-ball-y(make-ball 250 300 200 -4))
               296"Tentative position of ball's y coordinate should
 be returned (y+vy)")
  (check-equal?(check-ball-y(make-ball 250 -100 200 -4))
               104"Tentative position of ball's y coordinate
should be returned (-1)(y+vy)")
  (check-equal?(check-ball-y(make-ball 250 300 200 349))649
               "Initial-position of ball's y coordinate should be returned"))
 
  

;; check-ball-vx : World -> vx coordinate of ball
;;GIVEN: any world 
;;RETURNS: the vx coordinate of the ball as per the condition
;;on the current position of the ball vx coordinate
;;EXAMPLES:(check-ball-vx(make-world(make-racket 330 384 0 0)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        -200

;;;;DESIGN STRATEGY: Divide into conditions
;on the tentative position of vx coordinate 
(define (check-ball-vx  b)
  (cond
    ;;no wall
    [(and (> (newpos-x b) 0)
          (< (newpos-x b) X-MAX))
     (ball-vx b)]
    ;;left wall
    [(<= (newpos-x b) 0)
     ( * -1 (ball-vx  b))]
    ;;right wall
    [(>= (newpos-x b)X-MAX)
     ( * -1 (ball-vx  b))]
    ))
;;TESTS
(begin-for-test
  (check-equal?(check-ball-vx(make-ball 250 300 20 -4))
               20"ball's velocity x coordinate should be returned (vx)")
  (check-equal?(check-ball-vx(make-ball 150 -100 -200 -4))
               200" ball's velocity x coordinate
 should be returned (-1)(vx)")
  (check-equal?(check-ball-vx(make-ball 250 300 250 349))-250
               "ball's velocity x coordinate should be returned (-1)(vx)"))
 
  
;; check-ball-vy : World -> vy coordinate of ball
;;GIVEN: any world 
;;RETURNS: the vy coordinate of the ball as per the condition
;;on the current position of the ballv y coordinate
;;EXAMPLES:(check-ball-vy(make-world(make-racket 330 384 0 0)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        -349

;;;;DESIGN STRATEGY: Divide into conditions on
;the tentative position of vy coordinate
(define (check-ball-vy b)
  (cond
  
    ;;no wall
    [(and (> (newpos-y b) 0)
          (< (newpos-y b) Y-MAX))
     (ball-vy b)]
    ;;front wall
    [(<= (newpos-y b) 0)
     ( * -1 (ball-vy b))]
    [else (ball-vy b)] 
   
    ))
;;TESTS
(begin-for-test
  (check-equal?(check-ball-vy(make-ball 33 30 200 4))
               4"(rvy-bvy) should be returned ")
  (check-equal?(check-ball-vy(make-ball 250 -100 -200 -4))
               4" ball's velocity y coordinate should be returned (-1)(vy)")
  (check-equal?(check-ball-vy(make-ball 250 100 200 4))
               4" ball's velocity y coordinate should be returned (vy)")
  (check-equal?(check-ball-vy(make-ball 250 -30 250 3))-3
               "ball's velocity y coordinate should be returned (-1)(vy)")
  (check-equal?(check-ball-vy(make-ball 250 670 250 3))3
               "ball's velocity y coordinate should be returned (vy)"))

;; check-racket-x : World -> x coordinate of racket
;;GIVEN: any world 
;;RETURNS: the x coordinate of the racket as per the condition
;;on the current position of the racket x coordinate
;;EXAMPLES:(check-racket-x(make-world(make-racket 330 384 0 0)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        330

;;;;DESIGN STRATEGY:Divide into conditions on the
;tentative position of x coordinate
(define (check-racket-x ra)
  (cond
    ;;no wall
    [(and (> (newposr-x ra) 0)
          (< (newposr-x ra) X-MAX))
     (newposr-x ra)]
    ;;left wall
    [(<= (newposr-x ra) 0)
     23.5]
    ;;right wall
    [(>= (newposr-x ra) X-MAX)
     401.5]))

;;TESTS
(begin-for-test
  (check-equal?(check-racket-x(make-racket 330 384 15  20 false 0 0))
               345 "Tentative position of ball's x
coordinate should be returned (x+vx)")
  (check-equal?(check-racket-x(make-racket -30 384 -15  20 false 0 0)) 23.5
               "Racket should stick to the left wall")
  (check-equal?(check-racket-x(make-racket 300 384 150  20 false 0 0))401.5
               "Racket should stick to the right wall"))
 

;; check-racket-y : World -> y coordinate of racket
;;GIVEN: any world 
;;RETURNS: the y coordinate of the racket as per the condition
;;on the current position of the racket y coordinate
;;EXAMPLES:(check-racket-y(make-world(make-racket 330 384 -20 10)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        394

;;;;DESIGN STRATEGY: Divide into conditions on the
;tentative position of y coordinate
(define (check-racket-y ra)
  (cond
    ;;no wall
    [(and (> (newposr-y ra) 0)
          (< (newposr-y ra) Y-MAX))
     (newposr-y ra)]))
   
;;FUNCTIONS FOR TESTS
(define RTESTER4(make-racket 330 384 -20 10 false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(check-racket-y RTESTER4)394))
;; check-racket-vx : World -> vx coordinate of racket
;;GIVEN: any world 
;;RETURNS: the vx coordinate of the racket as per
;the condition on the current position of the racket vx coordinate
;;EXAMPLES:(check-racket-y(make-world(make-racket 330 384 -20 10)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        394

;;;;DESIGN STRATEGY: Divide into conditions on the
;tentative position of y coordinate
(define (check-racket-vx ra)
  (cond
    ;;no wall
    [(and (> (newposr-x ra) 0)
          (< (newposr-x ra) X-MAX))
     (racket-vx ra)]
    ;;left wall
    [(<= (newposr-x ra) 0)
     0]
    ;;right wall
    [(>= (newposr-x ra) X-MAX)
     0]))
;;FUNCTIONS FOR TESTS
(define RTESTER2(make-racket 333 34 -335 -40 true 330 384))
(define RTESTER3(make-racket 400 34 43 -40 true 330 384))
;;TESTS
(begin-for-test
  (check-equal?(check-racket-vx RTESTER2)0)
  (check-equal?(check-racket-vx RTESTER1)3)
  (check-equal?(check-racket-vx RTESTER3)0))


;; check-racket-vy : World -> vy coordinate of racket
;;GIVEN: any world 
;;RETURNS: the vy coordinate of the racket as per the condition
;;on the current position of the racket vy coordinate
;;EXAMPLES:(check-racket-y(make-world(make-racket 330 384 -20 10)
;;(make-ball 250 300 200 349)false 1 25 false))
;;                        394

;;;;DESIGN STRATEGY: Divide into conditions on the
;tentative position of y coordinate
(define (check-racket-vy ra)
  (cond
    ;;no wall
    [(and (> (newposr-y ra) 0)
          (< (newposr-y ra) Y-MAX))
     (racket-vy ra)]
      
    [(<= (newposr-y ra) 0)
     0]))
;;[(>= (newposr-y ra) Y-MAX)
;; "n/a"]))
;;FUNCTIONS FOR TESTS
(define RTESTER1(make-racket 330 -34 3 -40 true 330 384))
;;TESTS
(begin-for-test
  (check-equal?(check-racket-vy RTESTER)40)
  (check-equal?(check-racket-vy RTESTER1)0) )
  


;;; world-after-key-event;

;;CONTRACT:          
;; world-after-key-event : World KeyEvent -> World
;;GIVEN: a world and a key event
;;RETURNS: the world that should follow the given world
;;         after the given key event
;;EXAMPLES:(world-after-key-event(make-world
;(make-racket 20 30 50 60 false 0 0)
;;(list(make-ball 20  9 5 4))false 1 25 false 0 0)"up")->
;;(make-world (make-racket 20 30 50 59 false 0 0)
;;(list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
;;DESIGN STRATEGY: Cases on different keyevents-up,down,space,left,right
(define (world-after-key-event  w kev)
  (cond
    [(and(is-left-key-event? kev) (not(world-paused? w))
         (not(world-ready-to-serve? w)))(dec-speedvx w)]
    [(and(is-right-key-event? kev) (not(world-paused? w))
         (not(world-ready-to-serve? w)))(inc-speedvx w)]
    [(and(is-up-key-event? kev)   (not(world-paused? w))
         (not(world-ready-to-serve? w))) (dec-speedvy w)]
    [(and(is-down-key-event? kev) (not(world-paused? w))
         (not(world-ready-to-serve? w))) (inc-speedvy w)]
    [(and(is-space-key-event? kev)(not(world-paused? w))
         (world-ready-to-serve? w)) (rally-state w)]
    [(is-space-key-event? kev)(pause-world w)]
    [(and(is-b-key-event? kev)(not(world-paused? w))
         (not(world-ready-to-serve? w)))(add-ball w)]
    [else w]))
;;FUNCTIONS FOR TESTS
(define WORLDSAMPLE9(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))
                               false 1 25 false 0 0))
;;TESTS
(define SWORLD(make-world (make-racket 330 384 0 0 #f 1 1)
                          (list (make-ball 330 384 3 -9)) #f 1 25 #f 0 0))
(begin-for-test
  (check-equal?(world-after-key-event WORLDSAMPLE9 "up")
               (make-world (make-racket 333 401 50 59 #false 0 0)
                           (list (make-ball 20 9 5 4))
                           #false 1 25 #false 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 "down")
               (make-world (make-racket 333 401 50 61 #f 0 0)
                           (list (make-ball 20 9 5 4)) #f 1 25 #f 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 "left")
               (make-world (make-racket 333 401 49 60 #f 1 1)
                           (list (make-ball 20 9 5 4)) #f 1 25 #f 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 "right")
               (make-world (make-racket 333 401 51 60 #f 0 0)
                           (list (make-ball 20 9 5 4)) #f 1 25 #f 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 " ")
               (make-world (make-racket 333 401 50 60 #f 0 0)
                           (list (make-ball 20 9 5 4)) #t 1 25 #f 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 "b")
               (make-world (make-racket 333 401 50 60 #f 0 0)
                           (list (make-ball 330 384 3 -9)
                                 (make-ball 20 9 5 4)  ) #f 1 25 #f 0 0))
  (check-equal?(world-after-key-event WORLDSAMPLE9 " ")
               (make-world (make-racket 333 401 50 60 #f 0 0)
                           (list (make-ball 20 9 5 4)) #t 1 25 #f 0 0))
  (check-equal?(world-after-key-event(make-world
                                      (make-racket 20 30 50 60 false 0 0)
                                      (list(make-ball 20  9 5 4))
                                      false 1 25 true 0 0)" ")SWORLD)
  (check-equal?(world-after-key-event WORLDSAMPLE9 "c")WORLDSAMPLE9))

;; add-ball? : World -> World
;;GIVEN: a World
;;RETURNS: World after the addition of a ball in the list for b key event
;;EXAMPLE:
;;See tests
;;DESIGN STRATEGY: Use constructor template of ball list on b
(define(add-ball w)
  (make-world(world-racket w)
             (append  (cons (make-ball INIT-BALL-X INIT-BALL-Y
                                       READY-BALL-VX READY-BALL-VY)
                            empty)(world-balls w))
             false(world-ticks w) (world-speed w) false 0 0))
;;FUNCTIONS FOR TESTS
(define WORLDSAMPLE6(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))
                               false 1 25 false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(add-ball WORLDSAMPLE6) (make-world
                                        (make-racket 333 401 50 60 #f 0 0)
                                        (list (make-ball 330 384 3 -9)
                                              (make-ball 20 9 5 4))
                                        #f 1 25 #f 0 0)
               "new ball should be appended"))
           
            
 
;; is-space-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a space bar key event
;;EXAMPLE:
;;     (is-space-key-event? " ") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define (is-space-key-event? ke)
  (key=? ke " "))
;;TESTS
(begin-for-test
  (check-equal?(is-space-key-event? " ") true
               "true should be returned for spacebarkey event")
  (check-equal?(is-space-key-event? "4") false
               "false should be returned for non-spacebarkey event"))
   

;; is-left-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a left arrow key event
;;EXAMPLE:
;;     (is-space-key-event? "left") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define (is-left-key-event? ke)
  (key=? ke "left"))
;;TESTS
(begin-for-test
  (check-equal?(is-left-key-event? "left") true
               "true should be returned for leftkey event")
  (check-equal?(is-left-key-event? "4") false
               "false should be returned for non-left key event"))

;; is-right-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a right arrow key event
;;EXAMPLE:
;;     (is-space-key-event? "right") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define (is-right-key-event? ke)
  (key=? ke "right"))
;;TESTS
(begin-for-test
  (check-equal?(is-right-key-event? "right")
               true "true should be returned for rightkey event")
  (check-equal?(is-right-key-event? "left")
               false "false should be returned for non-right key event"))

;; is-up-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a up arrow key event
;;EXAMPLE:
;;     (is-space-key-event? "up") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define (is-up-key-event? ke)
  (key=? ke "up"))
;;TESTS
(begin-for-test
  (check-equal?(is-up-key-event? "left") false
               "false should be returned for nonleftkey event")
  (check-equal?(is-up-key-event? "up") true
               "true should be returned for leftkey event"))

;; is-down-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a down arrow key event
;;EXAMPLE:
;;     (is-space-key-event? "down") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define (is-down-key-event? ke)
  (key=? ke "down"))
;;TESTS
(begin-for-test
  (check-equal?(is-down-key-event? "down")
               true "true should be returned for b key event")
  (check-equal?(is-down-key-event? "left")
               false "false should be returned for non-down key event"))
;; is-b-key-event? : KeyEvent -> Boolean
;;GIVEN: a KeyEvent
;;RETURNS: true iff the KeyEvent represents a b press key event
;;EXAMPLE:
;;     (is-space-key-event? "b") = true
;;     (is-space-key-event? "c") = false
;;DESIGN STRATEGY: Combine simpler functions
(define(is-b-key-event? ke)
  (key=? ke "b"))
;;TESTS
(begin-for-test
  (check-equal?(is-b-key-event? "b")
               true "true should be returned for b key event")
  (check-equal?(is-b-key-event? "left") false
               "false should be returned for non-down key event"))
;;pause-world:World->World
;;GIVEN : a World
;;RETURNS : a World with the ispaused? as true
;;EXAMPLE:pause-world WORLDSAMPLE5->
;;(make-world(make-racket 333 401 50 60 #f 0 0)
;;(list (make-ball 20 9 5 4)) #t 1 25 #f 0 0)
;;DESIGN STRATEGY : use constructor template on w
(define WORLDSAMPLE5(make-world(make-racket 333 401 50 60 false 0 0)
                               (list(make-ball 20  9 5 4))true 1 25 false 0 0))

(define(pause-world w)
  (make-world
   (world-racket w)(world-balls w)true (world-ticks w)
   (world-speed w)(world-ready-to-serve? w)0 0))

;;;;TESTS
(begin-for-test
  (check-equal?(pause-world WORLDSAMPLE5)
               (make-world(make-racket 333 401 50 60 #f 0 0)
                          (list (make-ball 20 9 5 4)) #t 1 25 #f 0 0)
               "true should be returned for b key event"))

;;rally-state:World->World
;;GIVEN : a World
;;RETURNS : a World that has the racket velocity as (0,0)
;;ball velocity as ( 3,-9) and the racket and ball's
;;coordinates as (330,384)
;;EXAMPLE:(rally-state(make-world(make-racket 330 384 0 0 false 1 1)
;;(list(make-ball 330  384 0 0)false 1 25 false 0 0))->
;;(make-world (make-racket 330 384 0 0 false 1 1)
;;(list(make-ball 330 384 3 -9))
;;#false 1 25 #false 0 0))
;;DESIGN STRATEGY : Use constructor template on w
(define (rally-state w)
  (make-world
   (make-racket INIT-RACKET-X INIT-RACKET-Y
                INIT-RACKET-VX INIT-RACKET-VY false INIT-PTRXD INIT-PTRYD)
   (cons (make-ball INIT-BALL-X INIT-BALL-Y
                    READY-BALL-VX READY-BALL-VY)empty)
   false(world-ticks w) (world-speed w) false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(rally-state
                (make-world(make-racket 330 384 0 0 false 1 1)
                           (list(make-ball 330  384 0 0))false 1 25 false 0 0))
               (make-world
                (make-racket 330 384 0 0 false 1 1)
                (list(make-ball 330 384 3 -9))
                #false 1 25 #false 0 0)))
  


;;dec-speedvx:World->World
;;GIVEN : a World
;;RETURNS : a World that has the racket velocity (vx)
;;as vx-1,vy remaining same
;;EXAMPLE:(dec-speedvx(make-world(make-racket 20 30 50 60 false 0 0)
;;(list(make-ball 20  9 5 4))false 1 25 false 0 0))->
;;(make-world (make-racket 20 30 49 60 false 0 0)
;;(list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
;;DESIGN STRATEGY : Use constructor template on w
(define(dec-speedvx w)
  (make-world
   (make-racket (racket-x(world-racket w))
                ( racket-y(world-racket w)) (- (racket-vx(world-racket w))1)
                (racket-vy(world-racket w)) false INIT-PTRXD INIT-PTRYD )
   (world-balls w )false(world-ticks w) (world-speed w) false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(dec-speedvx(make-world(make-racket 20 30 50 60 false 0 0)
                                      (list(make-ball 20  9 5 4))
                                      false 1 25 false 0 0))
               (make-world (make-racket 20 30 49 60 false 1 1)
                           (list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
               "It should return the world
with racket's vy-1"))

;;inc-speedvx:World->World
;;GIVEN : a World
;;RETURNS : a World that has the racket velocity (vx)
;;as vx+1,vy remaining same
;;EXAMPLE:(inc-speedvx(make-world(make-racket 20 30 50 60 false 0 0)
;;(list(make-ball 20  9 5 4))false 1 25 false 0 0))->
;;(make-world (make-racket 20 30 51 60 false 0 0)
;;(list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
;;DESIGN STRATEGY : Use constructor template on w
(define(inc-speedvx w)
  (make-world
   (make-racket (racket-x(world-racket w)) ( racket-y(world-racket w))
                (+ (racket-vx(world-racket w))1)
                (racket-vy(world-racket w)) false 0 0 )
   (world-balls w )false(world-ticks w) (world-speed w) false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(inc-speedvx(make-world(make-racket 20 30 50 60 false 0 0)
                                      (list(make-ball 20  9 5 4))
                                      false 1 25 false 0 0))
               (make-world (make-racket 20 30 51 60 false 0 0)
                           (list(make-ball 20 9 5 4))
                           #false 1 25 #false 0 0)
               "It should return the world with racket's vx+1"))
  
;;dec-speedvy:World->World
;;GIVEN : a World
;;RETURNS : a World that has the racket velocity
;;(vy) as vy-1,vy remaining same
;;EXAMPLE:(dec-speedvy(make-world(make-racket 20 30 50 60 false 0 0)
;;(list(make-ball 20  9 5 4))false 1 25 false 0 0))->
;;(make-world (make-racket 20 30 50 59 false 0 0)
;;(list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
;;DESIGN STRATEGY : Use constructor template on w
(define(dec-speedvy w)
  (make-world
   (make-racket (racket-x(world-racket w)) ( racket-y(world-racket w))
                (racket-vx(world-racket w))(- (racket-vy(world-racket w))1)
                false 0 0)
   (world-balls w )false(world-ticks w) (world-speed w) false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(dec-speedvy(make-world(make-racket 20 30 50 60 false 0 0)
                                      (list(make-ball 20  9 5 4))
                                      false 1 25 false 0 0))
               (make-world (make-racket 20 30 50 59 false 0 0)
                           (list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
               "It should return the world
with racket's vy-1"))
;;inc-speedvy:World->World
;;GIVEN : a World
;;RETURNS : a World that has the racket velocity (vy)
;;as vy+1,vx remaining same
;;EXAMPLE:(inc-speedvy(make-world(make-racket 20 30 50 60 false 0 0)
;;(list(make-ball 20  9 5 4))false 1 25 false 0 0))->
;;(make-world (make-racket 20 30 50 61 false 0 0)
;;(list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
;;DESIGN STRATEGY : Use constructor template on w
(define(inc-speedvy w)
  (make-world
   (make-racket (racket-x(world-racket w)) ( racket-y(world-racket w))
                (racket-vx(world-racket w))(+ (racket-vy(world-racket w))1)
                false 0 0)
   (world-balls w )false(world-ticks w) (world-speed w) false 0 0))
;;TESTS
(begin-for-test
  (check-equal?(inc-speedvy(make-world(make-racket 20 30 50 60 false 0 0)
                                      (list(make-ball 20  9 5 4))
                                      false 1 25 false 0 0))
               (make-world (make-racket 20 30 50 61 false 0 0)
                           (list(make-ball 20 9 5 4)) #false 1 25 #false 0 0)
               "It should return the world
  with racket's vy+1"))


  
  
