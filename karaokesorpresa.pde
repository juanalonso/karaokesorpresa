//TEMAS:
//- No perder los saltos de línea
//- No perder las mayúsculas
//- Meter las sinalefas

//https://www.meaningcloud.com/developer/lemmatization-pos-parsing/doc
//https://store.apicultur.com/apis/info?name=BuscadorDeRimas&version=1.0.0&provider=MolinodeIdeas

import http.requests.*;

static final String meaningcloudKey = "";
static final String apiculturToken="";
static final String pythonPath ="";

static final String fichero = "base.txt";
static final String diccionario = "diccionario.txt";

abstract class SINTAXIS {
  static final int SUSTANTIVOS = 0;
  static final int ADJETIVOS = 1;
  static final int INFINITIVOS = 2;
  static final int ADVERBIOS = 3;
  static final int FINAL = 4;
}

//Texto completo, pero sin saltos de línea.
String textoCompleto;

//Array de diccionarios, uno por tipo sintáctico
StringList[] diccionarioRimas;

//Lista de todas las palabras y separadores, asociadas a un objeto Token
ArrayList<Token> listaTokensCompleta = new ArrayList<Token>();

//Lista de todas las palabras válidas, sin repeticiones. 
ArrayList<Token> listaTokensReducida = new ArrayList<Token>();


void setup() {

  diccionarioRimas = new StringList[SINTAXIS.FINAL];
  for (int f=0; f<SINTAXIS.FINAL; f++) {
    diccionarioRimas[f] = new StringList();
  }

  textoCompleto = cargarTexto();

  leerDiccionario();

  analizarTexto(textoCompleto);
  //println(listaTokensCompleta);

  filtrarTokens();

  int contTokens = 1;

  for (Token token : listaTokensReducida) {

    String palabraSustituta = null;

    if (token.palabra.indexOf(" ")!=-1) {
      palabraSustituta = token.palabra;
      println("[" + token.palabra + "] es una expresión, la ignoramos");
      continue;
    }

    //println("\nBuscando rimas para [" + token.palabra + "] en el diccionario");

    palabraSustituta = buscarRimaEnDiccionario(token);

    if (palabraSustituta==null) {

      println("Buscando <" + token.palabra + "|" + token.obtenerTipoPalabra() + "> en el API");
      //la palabra no está en el diccionario, accedemos al API
      Rimas r = descargarRimas(token);

      if (r.isEmpty()) {
        //Por lo que sea, no hay una palabra de la misma categoría que rime
        println("La palabra '" + token.palabra + "' no rima con ninguna otra palabra de la misma categoría");
      } else {
        //println(r.toString(true));

        //Hemos encontrado rimas (que pueden o no incluir la palabra original). Ampliamos el diccionario.
        completarDiccionario(r, token.tipoPalabra);
        grabarDiccionario(token.tipoPalabra);

        //Volvemos a buscar la palabra
        palabraSustituta = buscarRimaEnDiccionario(token);
        token.asignarSustituta(palabraSustituta);
      }
    } else {
      token.asignarSustituta(palabraSustituta);
    }

    println(contTokens  + "/"+ listaTokensReducida.size() +": "  + token.toString());
    contTokens++;
  }

  println("\n\n\n\n");

  for (int f=0; f<listaTokensCompleta.size(); f++) {

    Token tokenCompleta = listaTokensCompleta.get(f);

    String separador = "";

    if (f<listaTokensCompleta.size() - 1) {
      separador = obtenerSeparador(tokenCompleta, listaTokensCompleta.get(f+1));
    } 

    //println(tokenCompleta.tagInfo);
    //println(tokenCompleta.palabra);

    if (tokenCompleta.tipoPalabra == SINTAXIS.FINAL) {
      print(tokenCompleta.palabra + separador);
    } else {
      for (Token tokenReducida : listaTokensReducida) {
        if (tokenReducida.equals(tokenCompleta)) {
          print(tokenReducida.palabraSustituta + separador);
        }
      }
    }
  }
  println();

  noLoop();
}






//----------------------------------------------------------------------------------
String cargarTexto() {

  String texto ="";
  String[] lineas = loadStrings(fichero);

  for (String linea : lineas) {
    texto += linea + " ";
  }

  return texto;
}






//----------------------------------------------------------------------------------
void analizarTexto(String texto) {

  String textoEncoded = texto;
  try {
    textoEncoded = new String(texto.getBytes("UTF-8"), "ISO-8859-1");
  } 
  catch(Exception e) {
  }

  PostRequest post = new PostRequest("http://api.meaningcloud.com/parser-2.0");
  post.addData("key", meaningcloudKey);
  post.addData("lang", "es");
  post.addData("txt", textoEncoded);
  post.addData("verbose", "y");
  //post.addData("uw", "y");
  post.addData("src", "sdk-php-ma-2.0");
  post.addHeader("Content-Type", "application/x-www-form-urlencoded");
  post.send();

  String respuestaEncoded = post.getContent();
  try {
    respuestaEncoded = new String(respuestaEncoded.getBytes("ISO-8859-1"), "UTF-8");
  } 
  catch(Exception e) {
  }

  JSONObject responseJSON = parseJSONObject(respuestaEncoded);
  println("MeaningCloud: " + responseJSON.getJSONObject("status").getInt("remaining_credits") + " créditos");

  JSONArray listaFrases = responseJSON.getJSONArray("token_list");
  if (listaFrases!=null) {
    for (int f = 0; f < listaFrases.size(); f++) {
      JSONObject frase = listaFrases.getJSONObject(f);
      recorrerNodos(frase);
    }
  }
}


void recorrerNodos(JSONObject token) {

  JSONArray tokenList = token.getJSONArray("token_list");

  if (tokenList!=null) {

    for (int f = 0; f < tokenList.size(); f++) {

      JSONObject t = tokenList.getJSONObject(f);

      if (t.getJSONArray("token_list")!=null) {
        recorrerNodos(t);
      } else {

        if (t.getJSONArray("analysis_list")!=null) {

          String tagInfo = t.getJSONArray("analysis_list").getJSONObject(0).getString("tag_info");
          String originalForm = t.getJSONArray("analysis_list").getJSONObject(0).getString("original_form");

          int numSilabas = obtenerSilabas(originalForm);

          Token p = new Token(originalForm, numSilabas, tagInfo);

          //Hacemos un poco de filtro
          if (p.silabas < 2 && p.tipoPalabra == SINTAXIS.ADVERBIOS) {
            p.tipoPalabra = SINTAXIS.FINAL;
          }

          listaTokensCompleta.add(p);
        }
      }
    }
  }
}


int obtenerSilabas(String token) {

  Process p = exec(pythonPath, sketchPath()+"/silabeo.py", token);

  try {
    p.waitFor();
  } 
  catch (Exception e) {
    print(e.getMessage());
  }
  String[] silabas = loadStrings("numsilabas.txt");
  return int(silabas[0]);
}






//----------------------------------------------------------------------------------
void leerDiccionario() {

  for (int f=0; f<SINTAXIS.FINAL; f++) {

    String[] lineas = loadStrings(f + "_" + diccionario);
    for (String linea : lineas) {
      diccionarioRimas[f].append(trim(linea));
    }
  }
}


void completarDiccionario(Rimas r, int tipoPalabra) {
  String[] rimasComoArray = r.toArray();
  for (int f = 0; f < rimasComoArray.length; f++) {
    if (!rimasComoArray[f].equals("")) {
      diccionarioRimas[tipoPalabra].append(trim(rimasComoArray[f]));
    }
  }
}


void grabarDiccionario(int tipoPalabra) {

  String[] lineas = diccionarioRimas[tipoPalabra].array();

  //println("----" + lineas.toString() + "----");
  saveStrings(dataPath(tipoPalabra + "_" + diccionario), lineas);
}






//----------------------------------------------------------------------------------
void filtrarTokens() {
  for (Token token : listaTokensCompleta) {
    if (token.tipoPalabra < SINTAXIS.FINAL && !listaTokensReducida.contains(token)) {
      listaTokensReducida.add(token);
    }
  }
}





//----------------------------------------------------------------------------------
String buscarRimaEnDiccionario(Token t) {

  String rimaPropuesta = "";

  for (String listaRimas : diccionarioRimas[t.tipoPalabra]) {
    String[] posiblesRimas = split(listaRimas, " ");
    for (String rima : posiblesRimas) {
      if (t.palabra.equals(rima)) {
        if (posiblesRimas.length==1) {
          return rima;
        } else {
          rimaPropuesta = t.palabra;
          while (rimaPropuesta.equals(t.palabra)) {
            rimaPropuesta = posiblesRimas[(int)random(0, posiblesRimas.length)];
          }
          return rimaPropuesta;
        }
      }
    }
  }
  return null;
}


Rimas descargarRimas(Token t) {

  Rimas r = new Rimas();

  //1 = adjetivos, 2 = adverbios, 4 = sustantivos, 5 = verbos (incluye infinitivos)
  //según http://www.apicultur.com/2012/12/13/part-of-speech-codes-2/

  int tipoApicultur = 4; //Sustantivos
  if (t.tipoPalabra == SINTAXIS.ADJETIVOS) {
    tipoApicultur = 1;
  } else if (t.tipoPalabra == SINTAXIS.INFINITIVOS) {
    tipoApicultur = 5;
  } //else if (t.tipoPalabra == SINTAXIS.ADVERBIOS) {
    //Sí, esto está bien, que adverbios hay muy pocos
    //tipoApicultur = 4;
  //}

  String response = curl("https://store.apicultur.com/api/rima/1.0.0/"+t.palabra+"/true/"+tipoApicultur+"/10000/false");
  try {
    response = new String(response.getBytes("ISO-8859-1"), "UTF-8");
  } 
  catch(Exception e) {
  }
  JSONArray rimaArr = parseJSONArray(response);

  //Para tratar palabras como "balineses", que no están en la lista de sustantivos de Apicultur
  boolean palabraEncontrada = false;

  for (int f = 0; f < rimaArr.size(); f++) {

    JSONObject rimaObj = rimaArr.getJSONObject(f);
    String rima = rimaObj.getString("palabra");

    if (rima.equals(t.palabra)) {
      palabraEncontrada = true;
    }

    print(rima + " ");
    r.add(obtenerSilabas(rima), rima);
  }

  if (!palabraEncontrada) {
    println("***" + t.palabra + "***");
    r.add(obtenerSilabas(t.palabra), t.palabra);
  }
  println();

  return r;
}






//----------------------------------------------------------------------------------
String obtenerSeparador (Token tokAct, Token tokSig) {

  String separador = "*";

  boolean isActPuntuacion = tokAct.tagInfo.indexOf("puntuación")==0;
  boolean isSigPuntuacion = tokSig.tagInfo.indexOf("puntuación")==0;

  if (!isActPuntuacion && !isSigPuntuacion) {
    return " ";
  }

  if (isActPuntuacion && isSigPuntuacion) {
    return "";
  }


  if (isActPuntuacion) {
    if (tokAct.palabra.equals(".") || 
      tokAct.palabra.equals(",") ||
      tokAct.palabra.equals(";") ||
      tokAct.palabra.equals("?") ||
      tokAct.palabra.equals("\"") ||
      tokAct.palabra.equals("!")) {
      return " ";
    } else {
      return "";
    }
  }  

  if (isSigPuntuacion) {
    return "";
  }  


  return separador;
}






//----------------------------------------------------------------------------------
String curl(String URL) {
  delay(1050);
  GetRequest get = new GetRequest(URL);
  get.addHeader("Authorization", "Bearer " + apiculturToken);
  get.addHeader("content-type", "application/json");
  get.send();
  return get.getContent();
}
