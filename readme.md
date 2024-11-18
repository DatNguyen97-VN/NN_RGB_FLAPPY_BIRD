# A neural network of color detection for the flappy bird game
1. [Overview](#1-Overview)
2. [Ov7670](#2-Ov7670)
3. [NN RGB](#3-NN-RGB)
4. [Flappy Bird](#4-Flappy-Bird)
5. [Additional Features in The Future](#5-Additional-Features-in-The-Future)
6. [References](#6-References)

## 1. Overview
This is a hand-motion controlled Flappy Bird game where the player controls the bird's movement to avoid pipes, with points awarded for passing through gaps, and the game ending if the bird collides with a pipe. The game is displayed on a VGA screen.

https://github.com/user-attachments/assets/54c3d70f-76f3-4b28-b0e2-4ba5253c06c7

The idea is to design three main modules: OV7670, NN RGB, and Flappy Bird. The OV7670 module is responsible for gives data from the OV7670 camera, the NN RGB module is a neural network responsible for detecting skin color within a frame, then calculating the centroid of the hand and detecting whether the hand is moving vertically or horizontally. Finally, the Flappy Bird module creates the game logic and displays it on the VGA screen rely on the hand movement.

## 2. Ov7670
This module will process data from the camera in two steps:  
+ The first step sends the configuration set by the user to the camera via SCCB Interface, it is compatible with the I2C protocol.
+ The second step gets valid data based on the VGA frame timing and Horizontal timing.  

## 3. NN RGB 
Here’s a summary of the operation of the neural network with 3 input nodes (RGB), 1 hidden layer with 7 nodes, and 2 output nodes: 

**Input Layer:** The network receives 3 input values, which are the RGB values of a pixel. Each value represents the intensity of red, green, and blue in the pixel.  

**Hidden Layer:** The input values are passed through the first layer (hidden layer) with 7 nodes. Each input is multiplied by weights, and the result is passed through a linear activation function to extract simple features from the data.  

**Nonlinear Activation:** The output from the hidden layer is then passed through a nonlinear activation function, such as a sigmoid function, to extract more complex features and introduce non-linearity into the model.  

**Output Layer:** The network has 2 output nodes. Based on the learned weights and the computed features, the network decides whether the pixel is skin color or not. Each output corresponds to a binary classification of skin or non-skin.  

This structure allows the network to learn the pattern of skin color in the image and classify each pixel accordingly.  

## 4. Flappy Bird
Here’s a summary of the mechanism of the Flappy Bird Logic:  
**Game Objective:** The player controls a bird that needs to avoid pipes. The bird's movement is controlled by hand gestures detected by a camera. The goal is to pass through gaps in the pipes without colliding with them.  

**Game Loop:** The bird continuously moves forward at a fixed speed. The player controls the bird's vertical movement by moving their hand up or down (detected via skin detection and centroid tracking).
Pipes are generated at random intervals and move from right to left across the screen.  

**Scoring:** Each time the bird successfully passes through a gap between pipes, the player earns one point.
The score increases as the bird progresses through the gaps.  

**Collision Detection:** The game checks if the bird collides with a pipe. If a collision happens, the game ends.  

**Game Over and Win Condition:** The game ends when the bird collides with a pipe.
The game can also have a win condition based on a preset score (e.g., 5 points), at which point a victory message is displayed (not yet).  

**Display:** The game is displayed on a VGA screen, with the bird, pipes, and score rendered based on hand movements.  

## 5. Additional Features in The Future
**A low-pass filter** is used to process noise from the camera, as the current noise affects the NN RGB, causing errors in the centroid calculation of the hand.  

## 6. References  
1. FPGA4student, Basys 3 FPGA OV7670 Camera, https://www.fpga4student.com/2018/08/basys-3-fpga-ov7670-camera.html  
2. Mr. Marco Winzker, FPGA Design of a Neural Network for Color Detection, https://github.com/Marco-Winzker/NN_RGB_FPGA
3. The Flappy Bird Game, https://github.com/kiterunner347/flappy_bird  
