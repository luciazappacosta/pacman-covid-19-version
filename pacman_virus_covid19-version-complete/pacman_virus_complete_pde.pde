/*
*
 *  André Ribeiro Martins Marques Mourato/ NºMec: 84745
 *  José Diogo Xavier Monteiro/ NºMec: 84736
 *
 */

import ddf.minim.*;
Minim minim;
AudioPlayer intro, chump, death, speedUp, god, ghosts, silence;

import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;
ControlIO control;
ControlDevice stick;


import processing.serial.*;
import cc.arduino.*;

boolean firstStart = true;
boolean victory = false;

boolean firstArduino = true;
// ARDUINO PROPERTIES
int POWER = 5;
int SPEED = 6;
int PROGRAM = 7;
int MOT1 = 8;
int MOT2 = 9;


int BAUDRATE = 57600;

Arduino arduino;

long prevTime = 0;

boolean[] STEPS = {false, false, false, false, false, false, false, false, false, false};



BufferedReader reader;
PFont crackmanFont, lotFont;
String stage="menu";
int nCol, nLin;          // nº de linas e de colunas
int tamanho = 50;        // tamanho (largura e altura) das células do labirinto  
String direction;        // direção do pacman
int espacamento = 2;     // espaço livre entre células
int vel = 1;             // módulo da velocidade do pacman
float margemV, margemH;  // margem livre na vertical e na horizontal para assegurar que as células são quadrangulares
color corObstaculos;     // cor de fundo dos obstáculos
color corFronteira;
color corBolas;
color corPacman;
color red = color(255, 0, 0);
int red_vx, red_vy;                //Velocidades do fantasma vermelho
color blue = color(51, 204, 255);
int blue_vx, blue_vy;              //Velocidades do fantasma azul
color pink = color(255, 162, 122);
int pink_vx, pink_vy;              //Velocidades do fantasma rosa
int pink_pathCount;
color orange = color(255, 204, 0);
int orange_vx, orange_vy;          //Velocidades do fantasma laranja
int orange_pathCount;
int path[][];
boolean wasHere[][];

boolean invert; //Evento do jogo em que os fantasmas mudam de direção
boolean speed; //Evento que aumenta a velocidade do jogo
boolean godmode; //Evento que torna o pacman invulneravel

String text[]; //array da pontuação em String
int scores[]; //array da pontuação em valores inteiros
int leaderboard[]; //5 melhores pontuações

int numOnScreen; //numero de bolas
int numEaten; //número de bolas comidas
int score=0; //pontuação do jogador

PImage img1, img2;
boolean soundOn=true;
boolean pause=false;

// Posicao e tamanho do Pacman
float px, py, pRaio;

//velocidade na horizontal e vertical do Pacman
int vx, vy;

/*Posição dos fantasmas*/

//Fantasma vermelho
float red_px, red_py;

//Fantasma azul
float blue_px, blue_py;

//Fantasma rosa
float pink_px, pink_py;

//Fantasma laranja
float orange_px, orange_py;

//Corre uma vez
void setup() {

  size(720, 520);
  background(1);
  frameRate(200);
  
  
  control = ControlIO.getInstance(this);
  
  stick = control.getDevice(2);
  // Find a joystick that matches the configuration file. To match with any 
  // connected device remove the call to filter.
  //stick = control.filter(GCP.STICK).getMatchedDevice("pacman");
  if (stick == null) {
    println("No suitable device configured");
    System.exit(-1); // End the program NOW!
  }

  if(firstArduino){
      //ARDUINO CONNECTION
      arduino = new Arduino(this, Arduino.list()[0], BAUDRATE);
      for(int i = POWER; i<MOT2+1; i++){
        arduino.pinMode(i, Arduino.OUTPUT);
      }
      firstArduino= false;
  }

  
  //Velocidade inicial do pacman
  vx = 0;
  vy = 0;

  //Velocidade inicial dos fantasmas
  //Fantasma vermelho
  red_vx=0;
  red_vy=0;

  //Fantasma azul
  blue_vx=0;
  blue_vy=0;

  //Fantasma rosa
  pink_vx=0;
  pink_vy=0;

  //Fantasma laranja
  orange_vx=0;
  orange_vy=0;

  //Tipo de letra
  crackmanFont=createFont("crackman.TTF", 18);
  lotFont=createFont("lot.otf", 18);

  //Ficheiros
  reader = createReader("leaderboard.txt");
  text = loadStrings("leaderboard.txt");

  //Música
  minim = new Minim(this);
  intro = minim.loadFile("pacman_beginning.wav");
  intro.setGain(-12);
  chump = minim.loadFile("pacman_chomp.wav");
  chump.setGain(-20);
  death = minim.loadFile("pacman_death.wav");
  death.setGain(-10);
  speedUp = minim.loadFile("pacman_speed.wav");
  speedUp.setGain(-12);
  god = minim.loadFile("pacman_eatfruit.wav");
  god.setGain(-15);
  ghosts = minim.loadFile("pacman_ghosts.wav");
  ghosts.setGain(-12);
  silence = minim.loadFile("pacman_silence.wav");

  nCol = (int)(width/tamanho);
  nLin = (int)(height/tamanho);
  path = new int[nLin+2][nCol+2];//respetivamente altura e comprimento
  wasHere = new boolean[nLin+2][nCol+2]; //verifica se o pacman já passou pela casa
  leaderboard = new int[5];

  //Lê as pontuações existentes a partir do ficheiro
  readFile();
  readLeaderboard();

  // Assegurar que nº de linhas e nº de colunas é maior ou igual a 3
  assert nCol >= 5 && nLin >= 5;

  // Determinar margens para limitar a área útil do game 
  margemV = (width - nCol * tamanho) / 2.0;
  margemH = (height - nLin * tamanho) / 2.0;

  // Inicializar o Pacman
  px = centroX(9);
  py = centroY(5);
  pRaio = 30;

  //Não existem eventos no inicio do jogo
  invert=false; 
  speed=false;
  godmode=false;

  //Posição dos fantasmas

  //Fantasma vermelho
  red_px=centroX(9);
  red_py=centroY(1);

  //Fantasma azul
  blue_px=centroX(7);
  blue_py=centroY(5);

  //Fantasma rosa
  pink_px=centroX(3);
  pink_py=centroY(4);
  pink_pathCount=0;

  //Fantasma laranja
  orange_px=centroX(nCol);
  orange_py=centroY(7);
  orange_pathCount=0;
}

//Corre várias vezes
void draw() {
  
  
  if (stage=="menu") {
    img1 = loadImage("menu_inicial_1_original.jpg");
    image(img1, 0, 0);
    img2 = loadImage("pacman_letras.png");
    image(img2, 40, 80);
    buttonHighlight();
  }
  if (stage=="leaderboard") {

    background(0, 0, 112);
    //TOP 5
    fill(255, 255, 0);
    textFont(crackmanFont);
    textSize(60);
    text("Top 5", 70, 100);
    //1 LUGAR
    textFont(crackmanFont);
    fill(255, 255, 0);
    textSize(40);
    text("1st place: "+leaderboard[0]+" points", 100, 200);
    //2 LUGAR
    fill(255, 255, 0);
    textSize(40);
    text("2nd Place: "+leaderboard[1]+" points", 100, 240);
    //3 LUGAR
    fill(255, 255, 0);
    textSize(40);
    text("3rd Place: "+leaderboard[2]+" points", 100, 280);
    //4 LUGAR
    fill(255, 255, 0);
    textSize(40);
    text("4th Place: "+leaderboard[3]+" points", 100, 320);
    //5 LUGAR
    fill(255, 255, 0);
    textSize(40);
    text("5th Place: "+leaderboard[4]+" points", 100, 360);
    buttonHighlight();
  }
  if (stage=="ready") {
    background(0);
    fill(255, 255, 0);
    textSize(60);
    text("READY!", (width/2)-130, height/2);
    if (!intro.isPlaying()) stage="game";
  }
  if (stage=="game") {
    arduinoCheckScore();
    background(0);

    //Inverter trajetórias
    if (invert==false) {
      corObstaculos = color(50, 0, 200);
      corFronteira = color(80, 60, 200);
      corBolas = color(255);
    }
    if (invert==true) {
      corObstaculos = color(255, 69, 0);
      corFronteira = color(255, 0, 0);
    }

    //Eventos e mudança de cor
    if (speed==false) frameRate(200);
    if (speed==true) {
      if (godmode==false) corPacman=color(0, 255, 0);
      frameRate(350);
      if (!speedUp.isPlaying()) speed=false;
    }
    //Evento da invulnerabilidade
    if (godmode==true&&speed==true) corPacman = color(255, 128, 0);
    if (godmode==false&&speed==false) corPacman = color(255, 255, 0);
    if (godmode==false) {
      if (god.isPlaying()) god.pause();
      detectGhost();
    }
    if (godmode==true) {
      if (speed==false) corPacman = color(255, 0, 255);
      if (!god.isPlaying()) god.loop();
      if (!silence.isPlaying()) godmode=false;
    }

    desenharLabirinto();
    definePath();
    desenharPontos();
    printSpecials();
    desenharPacman();
    desenhaFantasmas();
    ghostPath();

    //Verifica se o evento está a ocorrer
    checkEvent();

    //pacman aparece do outro lado do ecrã quando sai dos limites
    px = (px + width) % width; //no eixo dos XX

    //Controla o pacman
    keyPressed();
    joystickInput(); // 

    //Deteção de colisão
    detectWall();

    //Bolas
    numOnScreen=ballCount();
    eatBall();
    numEaten=90-numOnScreen;
    score = numEaten;

    //Som
    if (!intro.isPlaying()) {
      sound();
    }

    //Verifica se ganhou o jogo
    victoryCheck();
  }
  if (stage=="death") {

    background(0);
    textFont(lotFont);
    fill(255, 0, 0);
    textSize(80);
    text("GAME OVER", (width/2)-260, height/2);
    textFont(crackmanFont);
    fill(255, 255, 0);
    textSize(40);
    text("Score: "+numEaten, (width/2)-250, (height/2)+120);
    if (isHighscore()) {
      fill(0, 255, 0);
      textSize(30);
      text("You've reached the leaderboard!", (width/2)-330, (height/2)+50);
    }
    resetSteps();
    buttonHighlight();
    writeToFile();
  }
  if (stage=="victory") {

    chump.mute();
    ghosts.mute();
    background(0);
    textFont(lotFont);
    fill(0, 255, 0);
    textSize(60);
    text("VICTORY!", (width/2)-170, height/2);
    textFont(crackmanFont);
    fill(255, 255, 0);
    textSize(40);
    text("Score: "+score, (width/2)-250, (height/2)+100);
    textFont(lotFont);
    resetSteps();
    buttonHighlight();
    writeToFile();
  }
  if (stage=="pause") {
    noLoop();
    textFont(lotFont);
    fill(255, 255, 0);
    textSize(40);
    text("Paused", centroX(6)-8, centroY(4)+14);
  }
  
  if(nonBlockingDelay(200) && stage=="game"){
     allPinLOW();
 }
}

/**************************
 *           MENU         *
 **************************/

public void arduino(){
  if(score> 4){
    println("motore1");
  }
}
//Escolhe a opção
public void mousePressed() {
  if (stage=="menu") {

    //JOGAR
    if (mouseX>90&&mouseX<230&&mouseY>285&&mouseY<330) {
      stage="ready";
      intro.play();
    }

    //Leaderboard
    if (mouseX>90&&mouseX<400&&mouseY>335&&mouseY<380) stage="leaderboard";

    //SAIR DO JOGO
    if (mouseX>90&&mouseX<210&&mouseY>385&&mouseY<430) exit();
  }
  if (stage=="leaderboard") {
    if (mouseX>290&&mouseX<400&&mouseY>410&&mouseY<460) stage="menu";
  }
  if (stage=="death") {
    if (mouseX>200&&mouseX<500&&mouseY>410&&mouseY<450) {
      direction="right";
      setup();
      intro.play();
      stage="ready";
    }
    if (mouseX>200&&mouseX<500&&mouseY>460&&mouseY<490) exit();
  }
  if (stage=="victory") {
    if (mouseX>200&&mouseX<500&&mouseY>410&&mouseY<450) {
      direction="right";
      setup();
      intro.play();
      stage="ready";
    }
    if (mouseX>200&&mouseX<500&&mouseY>460&&mouseY<490) exit();
  }
}

public void buttonHighlight() {
  if (stage=="menu") {
    textFont(lotFont);
    //Botão PLAY
    if (mouseX>90&&mouseX<230&&mouseY>285&&mouseY<330) {
      fill(0, 247, 255);
      textSize(50);
      text("Play", 80, 320);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Play", 80, 320);
    }

    //Botão LEADERBOARD
    if (mouseX>90&&mouseX<400&&mouseY>335&&mouseY<380) {
      fill(0, 247, 255);
      textSize(50);
      text("Leaderboard", 80, 370);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Leaderboard", 80, 370);
    }


    //Botão EXIT
    if (mouseX>90&&mouseX<210&&mouseY>385&&mouseY<430) {
      fill(0, 247, 255);
      textSize(50);
      text("Exit", 80, 420);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Exit", 80, 420);
    }
  }
  //LEADERBOARD
  if (stage=="leaderboard") {

    //Botão BACK
    if (mouseX>290&&mouseX<400&&mouseY>410&&mouseY<460) {
      fill(0, 247, 255);
      textSize(50);
      text("Back", 300, 450);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Back", 300, 450);
    }
  }
  //DEATH
  if (stage=="death") {
    if (mouseX>200&&mouseX<500&&mouseY>410&&mouseY<450) {
      textFont(lotFont);
      fill(0, 247, 255);
      textSize(50);
      text("Play again", 230, 440);
    } else {
      textFont(lotFont);
      fill(255, 255, 0);
      textSize(40);
      text("Play again", 230, 440);
    }
    if (mouseX>200&&mouseX<500&&mouseY>460&&mouseY<490) {
      fill(0, 247, 255);
      textSize(50);
      text("Exit", 300, 490);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Exit", 300, 480);
    }
  }
  if (stage=="victory") {
    if (mouseX>200&&mouseX<500&&mouseY>410&&mouseY<450) {
      fill(0, 247, 255);
      textSize(50);
      text("Play again", 230, 440);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Play again", 230, 440);
    }
    if (mouseX>200&&mouseX<500&&mouseY>460&&mouseY<490) {
      fill(0, 247, 255);
      textSize(50);
      text("Exit", 300, 490);
    } else {
      fill(255, 255, 0);
      textSize(40);
      text("Exit", 300, 480);
    }
  }
}


/***************************
 *           Jogo          *
 **************************/


//FUNÇAO DESENHA PACMAN EM CADA FRAME
void desenharPacman() {

  fill(corPacman);
  pushMatrix();
  translate(px+= vx, py-= vy);
  if (direction=="left") { 
    rotate(PI);
  }
  if (direction=="down") { 
    rotate(HALF_PI);
  }
  if (direction=="up") { 
    rotate( PI + HALF_PI );
  }
  if (vx!=0||vy!=0) arc(0, 0, pRaio, pRaio, map((millis() % 350), 50, 300, 0, 0.52), map((millis() % 350), 50, 300, TWO_PI, 5.76) ); //se estiver em movimento faz a animação
  else arc(0, 0, pRaio, pRaio, QUARTER_PI, (7*PI/4)); //se estiver parado para a animação
  popMatrix();
}

//funçao que desenha o mapa em cada frama
void desenharLabirinto () {

  // desenha a fronteira da área de game
  fill(0);
  stroke(corFronteira);
  strokeWeight(espacamento);
  rect(margemH, margemV, width - 2*margemH, height - 2*margemV);
  fill(0);
  noStroke();

  /*Saidas onde o pacman aparece do outro lado do ecrã*/

  //Saida do lado esquerdo
  rect(0, centroY(6)-25, 25, 50);
  stroke(corFronteira);
  line(centroX(0), centroY(6)-25, centroX(1)-25, centroY(6)-25);
  line(centroX(0), centroY(6)+25, centroX(1)-25, centroY(6)+25);

  //Saida do lado direito
  noStroke();
  rect(centroX(nCol)+10, centroY(6)-25, 25, 50);
  stroke(corFronteira);
  line(centroX(nCol)+25, centroY(6)+25, centroX(nCol+1), centroY(6)+25);
  line(centroX(nCol)+25, centroY(6)-25, centroX(nCol+1), centroY(6)-25);

  // Desenha obstáculos do tipo: (coluna, linha, largura XX, comprimento YY)
  desenharObstaculo(2, 2, 1, 2);
  desenharObstaculo(2, 5, 2, 1);
  desenharObstaculo(2, 7, 1, 3);
  desenharObstaculo(3, 7, 1, 1);
  desenharObstaculo(4, 2, 1, 3);
  desenharObstaculo(4, 9, 2, 1);
  desenharObstaculo(5, 6, 2, 1);
  desenharObstaculo(5, 7, 1, 1);
  desenharObstaculo(4, 2, 1, 3);
  desenharObstaculo(7, 8, 2, 2);
  desenharObstaculo(6, 4, 4, 1);
  desenharObstaculo(6, 2, 1, 1);
  desenharObstaculo(8, 2, 1, 2);
  desenharObstaculo(13, 2, 1, 2);
  desenharObstaculo(11, 2, 1, 3);
  desenharObstaculo(10, 2, 1, 1);
  desenharObstaculo(12, 5, 2, 1);
  desenharObstaculo(13, 7, 1, 3);
  desenharObstaculo(12, 7, 1, 1);
  desenharObstaculo(8, 6, 3, 1);
  desenharObstaculo(10, 8, 1, 2);
  desenharObstaculo(11, 9, 1, 1);
}

/* Desenha um obstáculo interno de um labirinto:
 x: índice da célula inicial segundo eixo dos X - gama (1..nCol) 
 y: índice da célula inicial segundo eixo dos Y - gama (1..nLin)
 numC: nº de colunas (células) segundo eixo dos X (largura do obstáculo)
 numL: nº de linhas (células) segundo eixo dos Y (altura do obstáculo) 
 */

//função que desenha o obstaculo: (coluna, linha, largura XX, comprimento YY)
void desenharObstaculo(int x, int y, int numC, int numL) {

  float x0, y0, larg, comp;
  x0 = margemH + (x-1) * tamanho;
  y0 = margemV + (y-1) * tamanho;
  larg = numC * tamanho;
  comp = numL * tamanho;
  fill(corObstaculos);
  noStroke();
  strokeWeight(espacamento/2);
  rect(x0, y0, larg, comp);
}

/*
Desenhar pontos nas células vazias (que não fazem parte de um obstáculo). 
 Esta função usa a cor de fundo no ecrã para determinar se uma célula está vazia ou se faz parte de um obstáculo.
 */
void desenharPontos() {

  float cx, cy;
  ellipseMode(CENTER);
  fill(255);
  noStroke();

  // Insere um ponto nas células vazias
  for (int i=1; i<=nCol; i++) {
    for (int j=1; j<=nLin; j++) {
      cx = centroX(i);
      cy = centroY(j);
      if (path[j][i]==2) {
        fill(corBolas);
        ellipse(cx, cy, 12, 12);
      }
    }
  }
}

/********************************
 *           Fantasmas          *
 *******************************/

//Desenha fantasmas
public void desenhaFantasmas() {

  //Fantasma vermelho
  criarFantasma((int)red_px, (int)red_py, red, red_vx, red_vy);
  //Fantasma azul
  criarFantasma((int)blue_px, (int)blue_py, blue, blue_vx, blue_vy);
  //Fantasma rosa
  criarFantasma((int)pink_px, (int)pink_py, pink, pink_vx, pink_vy);
  //Fantasma laranja
  criarFantasma((int)orange_px, (int)orange_py, orange, orange_vx, orange_vy);
}

//Cria fantasmas
public void criarFantasma(int x, int y, color c, int vx, int vy) {

  //Corpo dos fantasmas
 int d=36;//diametro da circunferencia
  int h=12;//altura do fantasma
  fill(c);
  circle(x, y, d);
  //UPº
  triangle(x - h/2, y, x+h/2, y, x, y-h-20);
  circle(x, y-h-20, 10);
  //DOWNº
  triangle(x - h/2, y, x+h/2, y, x, y+h+20);
  circle(x, y+h+20, 10);
  //RXº
  triangle(x, y - h/2, x, y+h/2, x+h+20, y);
  circle(x+h+20, y, 10);
  //LXº
  triangle(x, y - h/2, x, y+h/2, x-h-20, y);
  circle(x-h-20, y, 10);
  //UP-LX
  triangle(x - h/2, y, x+h/2, y, x-h-10, y-h-10);
  circle(x-h-10, y-h-10, 10);  
  //DOWN-RX
  triangle(x - h/2, y, x+h/2, y, x+h+10, y+h+10);
  circle(x+h+10, y+h+10, 10);
  //UP-RX
  triangle(x - h/2, y, x+h/2, y, x+h+10, y-h-10);
  circle(x+h+10, y-h-10, 10);
  //DOWN-LX
  triangle(x - h/2, y, x+h/2, y, x-h-10, y+h+10);
  circle(x-h-10, y+h+10, 10);

  //Olhos
  fill(255);
  ellipse(x-8, y-2, 13, 13);
  ellipse(x+8, y-2, 13, 13);

  //Os fantasmas olham na direção do seu movimento
  //Olha para a esquerda
  if (vx==-1) {
    fill(51, 102, 255);
    ellipse(x-10, y-2, 6, 9);
    ellipse(x+6, y-2, 6, 9);
    noStroke();
    //Olha para a direita
  } else if (vx==1) {
    fill(51, 102, 255);
    ellipse(x-6, y-2, 6, 9);
    ellipse(x+10, y-2, 6, 9);
    noStroke();
    //Olha para cima
  } else if (vy==1) {
    fill(51, 102, 255);
    ellipse(x-8, y-4, 6, 9);
    ellipse(x+8, y-4, 6, 9);
    noStroke();
    //Olha para baixo
  } else if (vy==-1) {
    fill(51, 102, 255);
    ellipse(x-8, y, 6, 9);
    ellipse(x+8, y, 6, 9);
    noStroke();
  }
}

/*******************************
 *           Movimento         *
 ******************************/

//Trajetória dos fantasmas
public void ghostPath() {

  //-----------------------------------//
  //  Se o invert não estiver a ocorrer//
  //-----------------------------------//

  if (invert==false) {
    //Fantasma vermelho
    translate(red_px+= red_vx, red_py-= red_vy);

    if (red_py>=centroY(1)&&red_px==centroX(9)) {
      red_vx=0;
      red_vy=-vel;
    }
    if (red_py==centroY(3)&&red_px==centroX(9)) {
      red_vx=vel;
      red_vy=0;
    }
    if (red_px==centroX(10)&&red_py>=centroY(3)) {
      red_vx=0;
      red_vy=-vel;
    }
    if (red_py==centroY(5)&&red_px==centroX(10)) {
      red_vy=0;
      red_vx=vel;
    }
    if (red_px==centroX(11)&&red_py==centroY(5)) {
      red_vx=0;
      red_vy=-vel;
    }
    if (red_py==centroY(6)&&red_px!=centroX(nCol)) {
      red_vx=vel;
      red_vy=0;
    }
    if (red_px==centroX(nCol)&&red_py>centroY(1)) {
      red_vx=0;
      red_vy=vel;
    }
    if (red_py==centroY(1)&&red_px>centroX(9)) {
      red_vx=-vel;
      red_vy=0;
    }

    //Fantasma azul
    translate(blue_px+= blue_vx, blue_py-= blue_vy);

    if (blue_px>centroX(4)&&blue_py==centroY(5)) {
      blue_vx=-vel;
      blue_vy=0;
    }
    if (blue_px==centroX(4)&&blue_py<centroY(6)) {
      blue_vx=0;
      blue_vy=-vel;
    }
    if (blue_py==centroY(6)&&blue_px>centroX(1)) {
      blue_vx=-vel;
      blue_vy=0;
    }
    if (blue_px==centroX(1)&&blue_py<centroY(nLin)) {
      blue_vy=-vel;
      blue_vx=0;
    }
    if (blue_py==centroY(nLin)&&blue_px<centroX(6)) {
      blue_vx=vel;
      blue_vy=0;
    }
    if (blue_px==centroX(6)&&blue_py>centroY(7)) {
      blue_vx=0;
      blue_vy=vel;
    }
    if (blue_py==centroY(7)&&blue_px>centroX(5)) {
      blue_vx=vel;
      blue_vy=0;
    }
    if (blue_py>centroY(5)&&blue_px==centroX(7)) {
      blue_vx=0;
      blue_vy=vel;
    }

    //Fantasma rosa
    translate(pink_px+= pink_vx, pink_py-= pink_vy);

    if (pink_px>centroX(1)&&pink_py==centroY(4)) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_px==centroX(1)&&pink_py>centroY(1)) {
      pink_vx=0;
      pink_vy=vel;
    }
    if (pink_py==centroY(1)&&pink_px<centroX(7)&&pink_pathCount==0) {
      pink_vx=vel;
      pink_vy=0;
    }
    if (pink_px==centroX(7)&&pink_py<centroY(3)) {
      pink_vx=0;
      pink_vy=-vel;
    }
    if (pink_py==centroY(3)&&pink_px>centroX(5)) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_px==centroX(5)&&pink_py>centroY(1)) {
      pink_vx=0;
      pink_vy=vel;
      if (pink_py==centroY(2))pink_pathCount=1;
    }
    if (pink_py==centroY(1)&&pink_px>centroX(1)&&pink_pathCount==1) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_py<centroY(4)&&pink_px==centroX(3)&&pink_pathCount==1) {
      pink_vx=0;
      pink_vy=-vel;
      if (pink_py==centroY(2))pink_pathCount=0;
    }

    //Fantasma laranja
    translate(orange_px+= orange_vx, orange_py-= orange_vy);

    if (orange_px==centroX(nCol)&&orange_py==centroY(7)) {
      orange_pathCount=0;
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_py==centroY(nLin)&&orange_px==centroX(nCol)&&orange_pathCount==0) {
      orange_vx=-vel;
      orange_vy=0;
    }
    if (orange_px==centroX(9)&&orange_py==centroY(nLin)) {
      orange_vx=0;
      orange_vy=vel;
    }
    if (orange_px==centroX(9)&&orange_py==centroY(7)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(7)) {
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(8)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(8)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(12)&&orange_py==centroY(8)) {
      orange_pathCount=1;
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_px==centroX(12)&&orange_py==centroY(nLin)&&orange_pathCount==1) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(nCol)&&orange_py==centroY(nLin)&&orange_pathCount==1) {
      orange_vx=0;
      orange_vy=vel;
      orange_pathCount=0;
    }
  }

  //------------------------------//
  // Se o evento estiver a ocorrer//
  //------------------------------//

  if (invert==true) {
    //Fantasma vermelho
    translate(red_px+= red_vx, red_py-= red_vy);

    if (red_py>centroY(1)&&red_px==centroX(9)) {
      red_vx=0;
      red_vy=vel;
    }
    if (red_py==centroY(3)&&red_px>centroX(9)) {
      red_vx=-vel;
      red_vy=0;
    }
    if (red_px==centroX(10)&&red_py>centroY(3)) {
      red_vx=0;
      red_vy=vel;
    }
    if (red_py==centroY(5)&&red_px>centroX(10)) {
      red_vy=0;
      red_vx=-vel;
    }
    if (red_px==centroX(11)&&red_py>centroY(5)) {
      red_vx=0;
      red_vy=vel;
    }
    if (red_py==centroY(6)&&red_px>centroX(11)) {
      red_vx=-vel;
      red_vy=0;
    }
    if (red_px==centroX(nCol)&&red_py<centroY(6)) {
      red_vx=0;
      red_vy=-vel;
    }
    if (red_py==centroY(1)&&red_px<centroX(nCol)) {
      red_vx=vel;
      red_vy=0;
    }

    //Fantasma azul
    translate(blue_px+= blue_vx, blue_py-= blue_vy);

    if (blue_px<centroX(7)&&blue_py==centroY(5)) {
      blue_vx=vel;
      blue_vy=0;
    }
    if (blue_px==centroX(4)&&blue_py>centroY(5)) {
      blue_vx=0;
      blue_vy=vel;
    }
    if (blue_py==centroY(6)&&blue_px<centroX(4)) {
      blue_vx=vel;
      blue_vy=0;
    }
    if (blue_px==centroX(1)&&blue_py>centroY(6)) {
      blue_vy=vel;
      blue_vx=0;
    }
    if (blue_py==centroY(nLin)&&blue_px>centroX(1)) {
      blue_vx=-vel;
      blue_vy=0;
    }
    if (blue_px==centroX(6)&&blue_py<centroY(nLin)&&blue_py!=centroY(5)) {
      blue_vx=0;
      blue_vy=-vel;
    }
    if (blue_py==centroY(7)&&blue_px>centroX(6)) {
      blue_vx=-vel;
      blue_vy=0;
    }
    if (blue_py<centroY(7)&&blue_px==centroX(7)) {
      blue_vx=0;
      blue_vy=-vel;
    }

    //Fantasma rosa
    translate(pink_px+= pink_vx, pink_py-= pink_vy);

    if (pink_px>centroX(1)&&pink_py==centroY(4)) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_px==centroX(1)&&pink_py>centroY(1)) {
      pink_vx=0;
      pink_vy=vel;
    }
    if (pink_py==centroY(1)&&pink_px<centroX(7)&&pink_pathCount==0) {
      pink_vx=vel;
      pink_vy=0;
    }
    if (pink_px==centroX(7)&&pink_py<centroY(3)) {
      pink_vx=0;
      pink_vy=-vel;
    }
    if (pink_py==centroY(3)&&pink_px>centroX(5)) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_px==centroX(5)&&pink_py>centroY(1)) {
      pink_vx=0;
      pink_vy=vel;
      if (pink_py==centroY(2))pink_pathCount=1;
    }
    if (pink_py==centroY(1)&&pink_px>centroX(1)&&pink_pathCount==1) {
      pink_vx=-vel;
      pink_vy=0;
    }
    if (pink_py<centroY(4)&&pink_px==centroX(3)&&pink_pathCount==1) {
      pink_vx=0;
      pink_vy=-vel;
      if (pink_py==centroY(2))pink_pathCount=0;
    }

    //Fantasma laranja
    translate(orange_px+= orange_vx, orange_py-= orange_vy);

    if (orange_px==centroX(nCol)&&orange_py==centroY(7)) {
      orange_pathCount=0;
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_py==centroY(nLin)&&orange_px==centroX(nCol)&&orange_pathCount==0) {
      orange_vx=-vel;
      orange_vy=0;
    }
    if (orange_px==centroX(9)&&orange_py==centroY(nLin)) {
      orange_vx=0;
      orange_vy=vel;
    }
    if (orange_px==centroX(9)&&orange_py==centroY(7)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(7)) {
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(8)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(11)&&orange_py==centroY(8)) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(12)&&orange_py==centroY(8)) {
      orange_pathCount=1;
      orange_vx=0;
      orange_vy=-vel;
    }
    if (orange_px==centroX(12)&&orange_py==centroY(nLin)&&orange_pathCount==1) {
      orange_vx=vel;
      orange_vy=0;
    }
    if (orange_px==centroX(nCol)&&orange_py==centroY(nLin)&&orange_pathCount==1) {
      orange_vx=0;
      orange_vy=vel;
      orange_pathCount=0;
    }
  }
}

// transformar o índice de uma célula em coordenada no ecrã
float centroX(int col) {
  return margemH + (col - 0.5) * tamanho;
}

// transformar o índice de uma célula em coordenada no ecrã
float centroY(int lin) {
  return margemV + (lin - 0.5) * tamanho;
}

/*Posição pacman*/
//No eixo dos XX
public int positionX(float px) {
  return (int)(((px-margemH)/tamanho)+0.5);
}

//No eixo dos YY
public int positionY(float py) {
  return (int)(((py-margemV)/tamanho)+0.5);
}


public void joystickInput() {
  float comX, comY;
  comX = stick.getSlider("X Axis").getValue();
  comY = stick.getSlider("Y Axis").getValue();
  
  println(comX);
  println(comY);
  
   switch((int)comX) {

      //Direita
    case 1:
      for (int i=1; i<nLin+1; i++) {
        if (py==centroY(i)&&turnRight()) {
          vx = vel;
          vy = 0;
          direction = "right";
        }
      }
      break;

      //Esquerda  
    case -1:
      for (int i=1; i<nLin+1; i++) {
        if (py==centroY(i)&&turnLeft()) {
          vx = -vel;
          vy = 0;
          direction = "left";
        }
      }
      break;
   }
   
    switch((int)comY) {

      //Direita
    case 1:
      for (int i=1; i<nCol+1; i++) {
        if (px==centroX(i)&&turnDown()) {
          vx = 0;
          vy = -vel;
          direction = "down";
        }
      }
      break;

      //Cima  
    case -1:
      for (int i=1; i<nCol+1; i++) {
        if (px==centroX(i)&&turnUp()) {
          vx = 0;
          vy = vel;
          direction = "up";
        }
      }
      break;
   }
}


//Controlo do Pacman
public void keyPressed() {

  if (key==CODED) {
    switch(keyCode) {

      //Direita
    case RIGHT:
      for (int i=1; i<nLin+1; i++) {
        if (py==centroY(i)&&turnRight()) {
          vx = vel;
          vy = 0;
          direction = "right";
        }
      }
      break;

      //Esquerda  
    case LEFT:
      for (int i=1; i<nLin+1; i++) {
        if (py==centroY(i)&&turnLeft()) {
          vx = -vel;
          vy = 0;
          direction = "left";
        }
      }
      break;

      //Baixo  
    case DOWN:
      for (int i=1; i<nCol+1; i++) {
        if (px==centroX(i)&&turnDown()) {
          vx = 0;
          vy = -vel;
          direction = "down";
        }
      }
      break;

      //Cima  
    case UP:
      for (int i=1; i<nCol+1; i++) {
        if (px==centroX(i)&&turnUp()) {
          vx = 0;
          vy = vel;
          direction = "up";
        }
      }
      break;
    }
  }
}

/*****************************
 *           Colisão         *
 ****************************/

//Define o array do mapa
public void definePath() {

  for (int j=0; j<=nLin+1; j++) {
    for (int i=0; i<=nCol+1; i++) {
      if (get((int)centroX(i), (int)centroY(j))!=corObstaculos&&wasHere[j][i]==false) path[j][i] = 2;
      if (i==0||j==0||i==nCol+1||j==nLin+1) path[j][i] = 0;
      if ((i==0||i==nCol+1)&&j==6) path[j][i]=3;
      if ((i==3&&j==3)||(i==12&&j==3)) path[j][i]=4;
      if (wasHere[8][4]==false) path[8][4]=4;
      if (wasHere[8][4]==true) path[8][4]=1;
      if (wasHere[8][11]==false) path[8][11]=4;
      if (wasHere[8][11]==true) path[8][11]=1;
    }
  }
}

//Verifica se pode virar à direita
public boolean turnRight() {
  if (path[positionY(py)][positionX(px)+1]!=0) return true;
  else return false;
}

//Verifica se pode virar à esquerda
public boolean turnLeft() {
  for (int j=1; j<=nLin; j++) {
    for (int i=1; i<=nCol; i++) {
      if (px==centroX(i)&&py==centroY(j)) {
        if (get((int)centroX(i-1), (int)centroY(j))==corObstaculos||px<=centroX(1)&&(j!=6))return false;
      }
    }
  }
  return true;
}

//Verifica se pode virar para baixo
public boolean turnDown() {
  if (path[positionY(py)+1][positionX(px)]!=0)return true;
  else return false;
}

//Verifica se pode virar para cima
public boolean turnUp() {
  for (int j=1; j<=nLin; j++) {
    for (int i=1; i<=nCol; i++) {
      if (px==centroX(i)&&py==centroY(j)) {
        if (get((int)centroX(i), (int)centroY(j-1))==corObstaculos||py<=centroY(1))return false;
      }
    }
  }
  return true;
}

//Deteta colisao
public void detectWall() {
  if (!turnRight()&&direction=="right") vx=0;
  if (!turnLeft()&&direction=="left") vx=0;
  if (!turnDown()&&direction=="down") vy=0;
  if (!turnUp()&&direction=="up") vy=0;
}

//detetacolisão com fantasmas
public void detectGhost() {

  //colisão com o fantasma vermelho
  if (dist(px, py, red_px, red_py)<18) {
    if(score> 7) power();
    death.play();
    intro.mute();
    chump.mute();
    speedUp.mute();
    ghosts.mute();
    stage="death";
  }
  //colisão com o fantasma azul
  if (dist(px, py, blue_px, blue_py)<18) {
    if(score> 7) power();
    death.play();
    intro.mute();
    chump.mute();
    speedUp.mute();
    ghosts.mute();
    stage="death";
  }
  //colisão com o fantasma rosa
  if (dist(px, py, pink_px, pink_py)<18) {
    if(score> 7) power();
    death.play();
    intro.mute();
    chump.mute();
    speedUp.mute();
    ghosts.mute();
    stage="death";
  }
  //colisão com o fantasma laranja
  if (dist(px, py, orange_px, orange_py)<18) {
    if(score> 7) power();
    death.play();
    intro.mute();
    chump.mute();
    speedUp.mute();
    ghosts.mute();
    stage="death";
  }
}

/************************
 *         Ovos         *
 ***********************/

//Conta os ovos
public int ballCount() {
  int balls=0;
  for (int j=0; j<=nLin+1; j++) {
    for (int i=0; i<=nCol+1; i++) {
      if (path[j][i]==2) balls++;
    }
  }
  return balls;
}

//Pacman come ovos
public void eatBall() {
  for (int j=0; j<=nLin+1; j++) {
    for (int i=0; i<=nCol+1; i++) {
      if (py==centroY(j)&&px==centroX(i)&&(path[j][i]==2||path[j][i]==4)) {
        wasHere[j][i]=true;
        path[j][i]=1;
      }
    }
  }
}

//Verifica se o jogador ganhou o jogo
public void victoryCheck() {
  if (numOnScreen==0) {
        power();
    stage="victory";
  }
}

/***********************************
 *             EVENTOS             *
 **********************************/

public void printSpecials() {
  printInvertBalls();
  printSpeedBalls();
  printGodmodeVaccine();
}

//INVERT
public void printInvertBalls() {
  if (invert==false) {
    fill(255, 0, 0);
    ellipse(centroX(12), centroY(3), 16, 16);
    ellipse(centroX(3), centroY(3), 16, 16);
  }
  if (invert==true) {
    fill(80, 60, 200);
    ellipse(centroX(12), centroY(3), 16, 16);
    ellipse(centroX(3), centroY(3), 16, 16);
  }
}

//SPEED
public void printSpeedBalls() {
  if (path[8][4]==4) {
    fill(0, 255, 0);
    ellipse(centroX(4), centroY(8), 16, 16);
  }
}

//GODMODE
public void printGodmodeVaccine() {
  if (path[8][11]==4) {
    fill(204, 204, 204);
    quad(centroX(11)-1, centroY(8)-42, centroX(11)+1, centroY(8)-42, centroX(11)+1, centroY(8)+42, centroX(11)-1, centroY(8)+42);
    quad(centroX(11)-6, centroY(8)-47, centroX(11)+6, centroY(8)-47, centroX(11)+6, centroY(8)-42, centroX(11)-6, centroY(8)-42);
    quad(centroX(11)-6, centroY(8)-22, centroX(11)+6, centroY(8)-22, centroX(11)+6, centroY(8)+22, centroX(11)-6, centroY(8)+22);
    fill(255, 0, 0);
    quad(centroX(11)-3, centroY(8)-6, centroX(11)+3, centroY(8)-6, centroX(11)+3, centroY(8)+12+7, centroX(11)-3, centroY(8)+12+7);
  }
}

public void checkEvent() {
  //Inverte a trajetoria dos fantasmas
  if ((px==centroX(12)&&py==centroY(3))||(px==centroX(3)&&py==centroY(3))) invert=!invert;
  //Acelera a velocidade do jogo
  if ((px==centroX(4)&&py==centroY(8))&&path[8][4]==4) {
    speed=true;
    speedUp.play();
  }
  if ((px==centroX(11)&&py==centroY(8))&&path[8][11]==4) { 
    godmode=true;
    silence.play();
  }
}



/************************************
 *           Teclas premidas        *
 ***********************************/

public void keyTyped() {
  if (key=='m'||key=='M') soundToggle();
  if (key==' ') {
    if (stage=="game"||stage=="pause") pauseToggle();
  }
}

/************************************
 *           MENU DE PAUSA          *
 ***********************************/

//Pausa ou jogar
public void pauseToggle() {
  pause=!pause;
  pauseControl();
}

//Controlo de pausa
public void pauseControl() {

  if (pause) {
    stage="pause";
    intro.mute();
    chump.mute();
    death.mute();
    god.mute();
    speedUp.mute();
    silence.pause();
  }
  if (!pause) {
    loop();
    stage="game";
    intro.unmute();
    chump.unmute();
    death.unmute();
    god.unmute();
    speedUp.unmute();
    silence.play();
  }
}

/**************************
 *           Som          *
 **************************/

public void sound() {
  if (!chump.isPlaying()&&(vx!=0||vy!=0)) chump.loop();
  if (vx==0&&vy==0) chump.pause();
  if (!ghosts.isPlaying()) ghosts.loop();
}

//Com som ou sem som
public void soundToggle() {
  soundOn=!soundOn;
  soundControl();
}

//Associada à soundToggle
public void soundControl() {

  //Desliga o som
  if (!soundOn) {
    intro.mute();
    chump.mute();
    death.mute();
    speedUp.mute();
    ghosts.mute();
    god.mute();
  }

  //Liga o som
  if (soundOn) {
    intro.unmute();
    chump.unmute();
    death.unmute();
    speedUp.unmute();
    ghosts.unmute();
    god.unmute();
  }
}

/********************************
 *           FICHEIROS          *
 *******************************/

void readFile() {
  scores = new int[text.length];
  for (int i = 0; i < scores.length; i++) {
    scores[i] = Integer.parseInt(text[i]);
  }
  sortArray(scores); //coloca os elementos por ordem
}

//Vai buscar os 5 primeiros elementos do array score[], que são os 5 maiores (visto que este foi ordenado por ordem decrescente)
void readLeaderboard() {

  for (int i = 0; i <leaderboard.length; i++) {
    leaderboard[i]=scores[i];
  }
}

//Organiza o array por ordem decrescente
void sortArray(int array[]) {
  int tmp, i, j;
  for (i = 0; i < array.length - 1; i++) { 
    for (j = i + 1; j < array.length; j++) { 
      if (array[i] < array[j]) 
      {
        tmp = array[i];
        array[i] = array[j];
        array[j] = tmp;
      }
    }
  }
}

//Escreve as novas pontuações no ficheiro
void writeToFile() {
  PrintWriter write;
  write = createWriter("leaderboard.txt");
  for (int i=0; i<scores.length; i++) {
    write.println(scores[i]);
  }
  write.println(score); //escreve a nova pontuação no ficheiro
  write.flush();
  write.close();
}

boolean isHighscore() {
  for (int i=4; i>=0; i--) {
    if (score>leaderboard[i]) return true;
  }
  return false;
}


// Arduino fucntion

boolean nonBlockingDelay(int delay){
  if(millis() - prevTime >= delay){
    prevTime = millis();
    return true;
  }else{
      return false;
  }

}

void allPinLOW(){
  
  for(int i = POWER; i<MOT2+1; i++){
    arduino.digitalWrite(i, Arduino.HIGH);
  }
}


void sendCommand(int pin){
   arduino.digitalWrite(pin, Arduino.LOW);
   //reset counter
   prevTime = millis();
}


/*
PIN 
int POWER = 5;
int SPEED = 6;
int PROGRAM = 7;
int HEAT = 8;
int MOT1 = 9;
int MOT2 = 10;
int MOT3 = 11;
*/
void arduinoCheckScore(){
  if (score> 7 && score <14 && !STEPS[0]){
    //STEP0
    println("Motor1");
    sendCommand(POWER);
    STEPS[0] = true;
  }
  else if(score >14 && score <21 && !STEPS[1]){
    //STEP1
    println("Motor2");
    sendCommand(SPEED);
    STEPS[1] = true;
  }
  else if(score >21 && score <28 && !STEPS[2]){
    //STEP2
    println("Massage");
    sendCommand(SPEED);
    STEPS[2] = true;
  }
  else if(score >28 && score <35 && !STEPS[3]){
    //STEP3
    println("Speedup");
    sendCommand(SPEED);
    STEPS[3] = true;
  }
  else if(score >35 && score <42 && !STEPS[4]){
    //STEP4
    println("Speedup up");
    sendCommand(PROGRAM);
    STEPS[4] = true;
  }
  else if(score >42 && score <49 && !STEPS[5]){
    //STEP5
    println("Massage");
    sendCommand(SPEED);
    STEPS[5] = true;
  }
  else if(score >49 && score <56 && !STEPS[6]){
    //STEP6
    println("Massage");
    sendCommand(PROGRAM);
    STEPS[6] = true;
  }
  else if(score >56 && score <63 && !STEPS[7]){
    //STEP6
    println("Massage");
    sendCommand(SPEED);
    STEPS[7] = true;
  }
  else if(score >63 && score <70 && !STEPS[8]){
    //STEP6
    println("Massage");
    sendCommand(SPEED);
    STEPS[8] = true;
  }  
}

void resetMassage(){
  /*if (victory){
    power();
    victory = false;
  }*/
  /*power();
  sendCommand(SPEED);
  delay(500);
  allPinLOW();
  delay(500);
  sendCommand(SPEED);
  delay(500);
  allPinLOW();
  delay(500);
  */
}

void power(){
  delay(1000);
  sendCommand(POWER);
  delay(1000);
  allPinLOW();
  delay(1000);
}
void resetSteps(){
  //arduino.dispose();
  for(int i = 0; i< STEPS.length; i++){
        STEPS[i] = false;
  }
}
