import SwiftUI
import WatchKit

struct ContentView: View {
    // Game state
    @State private var ballPosition = CGPoint(x: 100, y: 100)
    @State private var ballVelocity = CGVector(dx: 2, dy: -2)  // Changed initial velocity to move upward (negative y)
    @State private var paddlePosition: CGFloat = 100
    @State private var score = 0
    @State private var lives = 3
    @State private var isGameActive = false
    @State private var showingGameOver = false
    
    // Focus state for Digital Crown
    @FocusState private var isFocused: Bool
    
    // Game constants
    private let ballSize: CGFloat = 10
    private let paddleWidth: CGFloat = 60
    private let paddleHeight: CGFloat = 10
    private let screenWidth: CGFloat = 200
    private let screenHeight: CGFloat = 200
    
    // Ball movement constants
    private let initialBallSpeed: CGFloat = 2.0    // Reduced from 3.0 for slower movement
    private let speedIncreaseFactor: CGFloat = 1.05  // Reduced from 1.1 for more gradual speed increase
    
    // Timer for game loop
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            if !isGameActive && !showingGameOver {
                // Start screen
                VStack {
                    Text("Pong")
                        .font(.title)
                        .foregroundColor(.white)
                    Button("Start Game") {
                        startGame()
                    }
                    .foregroundColor(.green)
                }
            } else if showingGameOver {
                // Game Over screen
                VStack(spacing: 10) {
                    Text("Game Over!")
                        .font(.title3)
                        .foregroundColor(.red)
                    Text("Final Score: \(score)")
                        .foregroundColor(.white)
                    Button("Play Again") {
                        startGame()
                    }
                    .foregroundColor(.green)
                }
            } else {
                // Game elements
                // Ball
                Circle()
                    .fill(Color.white)
                    .frame(width: ballSize, height: ballSize)
                    .position(ballPosition)
                
                // Paddle
                Rectangle()
                    .fill(Color.white)
                    .frame(width: paddleWidth, height: paddleHeight)
                    .position(x: paddlePosition, y: screenHeight - 20)
                
                // Score and Lives display
                HStack {
                    Text("Score: \(score)")
                        .foregroundColor(.white)
                    Spacer()
                    // Display hearts for lives
                    HStack(spacing: 4) {
                        ForEach(0..<lives, id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .position(x: screenWidth/2, y: 20)
            }
        }
        // Digital Crown control
        .focusable(true)
        .focused($isFocused)
        .digitalCrownRotation($paddlePosition, from: paddleWidth/2, through: screenWidth - paddleWidth/2, by: 1.0, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onReceive(timer) { _ in
            if isGameActive {
                updateBallPosition()
            }
        }
    }
    
    private func startGame() {
        // Reset game state
        ballPosition = CGPoint(x: screenWidth/2, y: screenHeight - 40)  // Start above paddle
        // Initialize ball velocity moving upward
        ballVelocity = CGVector(dx: initialBallSpeed * 0.5, dy: -initialBallSpeed)
        paddlePosition = screenWidth/2
        score = 0
        lives = 3
        isGameActive = true
        showingGameOver = false
        // Ensure Digital Crown control is active
        isFocused = true
    }
    
    private func resetBall() {
        // Reset ball to just above paddle with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ballPosition = CGPoint(x: screenWidth/2, y: screenHeight - 40)
            // Start moving upward with slight random horizontal movement
            let randomHorizontal = Double.random(in: -0.5...0.5)
            ballVelocity = CGVector(dx: initialBallSpeed * randomHorizontal, dy: -initialBallSpeed)
        }
    }
    
    private func updateBallPosition() {
        // Update ball position based on velocity
        ballPosition.x += ballVelocity.dx
        ballPosition.y += ballVelocity.dy
        
        // Bounce off walls
        if ballPosition.x <= 0 || ballPosition.x >= screenWidth {
            ballVelocity.dx *= -1
        }
        
        // Bounce off ceiling
        if ballPosition.y <= 0 {
            ballVelocity.dy *= -1
        }
        
        // Check for paddle collision
        if ballPosition.y >= screenHeight - 30 && ballPosition.y <= screenHeight - 10 {
            if abs(ballPosition.x - paddlePosition) < paddleWidth/2 {
                ballVelocity.dy *= -1
                score += 1
                // Increase speed slightly with each hit
                ballVelocity.dx *= speedIncreaseFactor
                ballVelocity.dy *= speedIncreaseFactor
                // Add haptic feedback for successful hit
                WKInterfaceDevice.current().play(.success)
            }
        }
        
        // Check for missing the paddle
        if ballPosition.y > screenHeight {
            lives -= 1
            // Add haptic feedback for losing a life
            WKInterfaceDevice.current().play(.failure)
            
            if lives > 0 {
                resetBall()
            } else {
                // Game Over
                isGameActive = false
                showingGameOver = true
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}
