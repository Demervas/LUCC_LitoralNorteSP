-- Local desenvolvimento: Laboratório de Geomática - Engenharia de Infraestrutura Aeronáutica.
-- Título: Código Lua/TerraME - Modelagem dinâmica espacial dos municípios do Litoral Norte Paulista.
-- Desenvolvedor: Demerval Aparecido Gonçalves.
-- Finalidade: Implementação de um modelo LUCC para o Litoral Norte Paulista.
-- Versão: 1.1.
-- Saída: mensagens de execução e atribuição de valores dos atributos do espaço celular.
-- Requisitos para execução:
-- Espaço celular contido no arquivo 'C:\LNModelos\LUCC\luccln.mdb' com os atributos devidamente preenchidos. 
-- Arquivo de pesos de evidência ('C:\LNModelos\LUCC\lnpesosevidencia.dcf') no formato gerado pelo software DINAMICA EGO.
-- Arquitetura TerraME instalada.
-- Aplicativo Crimson Editor instalado.
-- O simbolo decimal deve ser '.' (ponto) e o de agrupamento de digitos deve ser ',' (virgula) nas opcoes regionais e de idioma para que os valores do banco de dados seja lido com precisao. 
-- O código pode ser executado para gerar prognósticos de 2015 e de 2044, e para isso deve ser habilitados os blocos de código devidamente identificados pelos comentários '-- 2015s:' e '-- 2044s:'.

--Calculo de determinacao do padrao de alteracao da vizinhanca
function calculaneig(pCelula)
  QtNaoAlterado = 0;
  QtAlterado = 0;
  QtNeig8615 = {0,0,0,0,0,0,0,0,0};
  for i, cell in pairs(csP.cells) do
    if (cell.past.NF86 == 1) and (cell.past.NF15 == 2) then
      QtDesmate = 0;
      ForEachNeighbour(cell,0,
      function(cell,neigh)
        if (neigh.past.NF86 == 2 and cell ~= neigh) then
          QtDesmate = QtDesmate + 1;
        end
      end
      );
      QtAlterado = QtAlterado + 1;
      QtNeig8615[QtDesmate + 1] = QtNeig8615[QtDesmate + 1] + 1;
    else
      QtNaoAlterado = QtNaoAlterado + 1;
    end
  end  
  print("\nPerfil da vizinhança das células alteradas historicamente");
  print("-------------------------------------------");
  print("TRANSICOES DE 1986 A 2015");  
  QtNeig = QtNeig8615;
  for cont = 1, 9, 1 do
    print(cont - 1,":",QtNeig[cont]);
  end
  print("Celulas alteradas: ", QtAlterado, ". Celulas nao alteradas: ",QtNaoAlterado, ".");  
  print("-------------------------------------------");
  return QtNeig8615, QtAlterado;
end

-- função lepesos.fragmentalinha: cria vetor com valores separados a partir de uma linha do arquivo texto de pesos de evidência.
-- parâmetros - pTipo: define se alinha é de cabecalho ou de valores; pLinha: linha do arquivo de pesos de evidencia que será processada.
-- retorna uma matriz, através da variável Fragmentos, os fragmentos da linha recebida.
-- CaracterInicial e CaracterFinal: armazenam a primeira e a última posição do texto a ser extraído de pLinha.
-- terminou: flag que indica o final da linha.
-- cont2: indexador do vetor Fragmentos.
function fragmentalinha(pTipo, pLinha)
  Fragmentos = {};
  if (pTipo == 1) then -- linha de cabecalho.
    -- Lê o nome da variável estática e armazena como primeira célula.
    CaracterInicial = string.find (pLinha, "/",caracter) + 1;
    CaracterFinal = CaracterInicial;
    while string.byte(string.sub(pLinha,CaracterFinal+1,CaracterFinal+1)) ~= 9 do
      CaracterFinal = CaracterFinal + 1;
    end
    Fragmentos[1] = string.sub(pLinha,CaracterInicial,CaracterFinal)
    -- Lê os limites dos intervalos dos pesos de evidência e armazena como primeira linha.
    terminou = false;
    CaracterFinal = CaracterFinal + 1;
    cont2 = 2;
    while terminou == false do
      CaracterInicial = string.find (pLinha, ":",CaracterFinal);
      if (CaracterInicial ~= nil) then
        CaracterInicial = CaracterInicial + 1;
        CaracterFinal = CaracterInicial;
        while (string.byte(string.sub(pLinha,CaracterFinal+1,CaracterFinal+1)) ~= 9) and (CaracterFinal < string.len(pLinha)) do
          CaracterFinal = CaracterFinal + 1;
        end
        Fragmentos[cont2] = string.sub(pLinha,CaracterInicial,CaracterFinal)
        cont2 = cont2 + 1;
        if (CaracterFinal+1 > string.len(pLinha)) then
          terminou = true;
        end
      end
    end
  else -- linha de valores.
    -- Lê a transição e armazena na primeira célula.
    CaracterInicial = 1;
    CaracterFinal = CaracterInicial;
    while string.byte(string.sub(pLinha,CaracterFinal+1,CaracterFinal+1)) ~= 9 do
      CaracterFinal = CaracterFinal + 1;
    end
    Fragmentos[1] = string.sub(pLinha,CaracterInicial,CaracterFinal)
    -- Lê os pesos de evidência e armazena como segunda linha.
    terminou = false;
    CaracterFinal = CaracterFinal + 2;
    cont2 = 2;
    while terminou == false do
      CaracterInicial = CaracterFinal;
      while (string.byte(string.sub(pLinha,CaracterFinal+1,CaracterFinal+1)) ~= 9) and (CaracterFinal < string.len(pLinha)) do
        CaracterFinal = CaracterFinal + 1;
      end
      Fragmentos[cont2] = string.sub(pLinha,CaracterInicial,CaracterFinal)
      cont2 = cont2 + 1;
      if (CaracterFinal+1 > string.len(pLinha)) then
        terminou = true;
      end
      CaracterFinal = CaracterFinal + 2;
    end
  end
  return Fragmentos;
end

-- funcao lepesos: lê cada linha do arquivo texto de pesos de evidência e monta uma matriz.
-- parâmetros - pArquivo: nome do arquivo de pesos de evidência que será lido.
-- retorna, através da variável PesosLidos, uma matriz com os pesos lidos do arquivo texto.
-- cont1: indexador da matriz PesosLidos.
function lepesos(pArquivo)
  PesosLidos = {};
  cont1 = 0;
  Linhas = {};
  for line in io.lines(pArquivo) do 
    cont1 = cont1 + 1;
    Linhas[cont1] = line;
    PesosLidos[cont1] = fragmentalinha(math.mod(cont1,2),line);
  end
  return PesosLidos;  
end

-- Função que calcula a favorabilidade da transição FLORESTA/NAO FLORESTA de acordo com pesos de evidência.
-- parâmetros - pCelula: célula do espaço celular; pMatrizPesos: matriz que contém todos os pesos de evidência.
-- retorna, através da variável Potencial o valor calculado da favorabilidade de transição da célula de entrada.
-- Erro: flag que indica erro na localização do peso de evidência na matriz pMatrizPesos.
-- x e y: indexadores da matriz pMatrizPesos.
function calcula_potencial(pCelula,pMatrizPesos)
  Potencial = 0;
  Erro = 0;
 
  -- area protegida
  x = 1;
  y = 2;
  while (pMatrizPesos[x][1] ~= "PROTEG") and (pMatrizPesos[x][1] ~= nil) do
    x = x + 2;
  end  
  while ((pMatrizPesos[x][y]+0) <= (pCelula.past.PROTEG+0)) and (pMatrizPesos[x][y] ~= nil) do
    y = y + 1;
  end
  x = x + 1;
  if pMatrizPesos[x][y] ~= nil then
    pCelula.prot = pMatrizPesos[x][y]+0;
    -- Potencial = Potencial + pMatrizPesos[x][y]; -- Essa variavel foi desconsiderada
  else
    Erro = 1;
  end
  
  -- distancia de nao floresta.
  x = 1;
  y = 2;
  while (pMatrizPesos[x][1] ~= "DNF86") and (pMatrizPesos[x][1] ~= nil) do
    x = x + 2;
  end  
  while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DNF15+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
  -- 2015s:
  -- while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DNF86+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
  -- 2044s:
  -- while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DNF15+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
    y = y + 1;
  end
  x = x + 1;
  if pMatrizPesos[x][y] ~= nil then
    pCelula.nflo15 = pMatrizPesos[x][y]+0;
    -- 2015s:
    --pCelula.nflo86 = pMatrizPesos[x][y]+0;
    -- 2044s:
    --pCelula.nflo15 = pMatrizPesos[x][y]+0;
    Potencial = Potencial + pMatrizPesos[x][y];
  else
    Erro = 1;
  end

  -- drenagem.
  x = 1;
  y = 2;
  while (pMatrizPesos[x][1] ~= "DDRENA") and (pMatrizPesos[x][1] ~= nil) do
    x = x + 2;
  end  
  while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DDRENA+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
    y = y + 1;
  end
  x = x + 1;
  if pMatrizPesos[x][y] ~= nil then
    pCelula.dren = pMatrizPesos[x][y]+0;
    Potencial = Potencial + pMatrizPesos[x][y];
  else
    Erro = 1;
  end

  -- rodovias.
  x = 1;
  y = 2;
  while (pMatrizPesos[x][1] ~= "DROD86") and (pMatrizPesos[x][1] ~= nil) do
    x = x + 2;
  end  
  while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DROD15+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
  -- 2015s:
  -- while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DROD86+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
  -- 2044s:
  -- while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DROD15+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
    y = y + 1;
  end
  x = x + 1;
  if pMatrizPesos[x][y] ~= nil then
    pCelula.rod15 = pMatrizPesos[x][y]+0;
    -- 2015s:
    -- pCelula.rod86 = pMatrizPesos[x][y]+0;
    -- 2044s:
    -- pCelula.rod15 = pMatrizPesos[x][y]+0;
    Potencial = Potencial + pMatrizPesos[x][y];
  else
    Erro = 1;
  end
  
  -- declividade.
  x = 1;
  y = 2;
  while (pMatrizPesos[x][1] ~= "DECLIVI") and (pMatrizPesos[x][1] ~= nil) do
    x = x + 2;
  end  
  while ((pMatrizPesos[x][y]+0) <= (pCelula.past.DECLIVI+0)) and  ((pMatrizPesos[x][y]) ~= nil) do
    y = y + 1;
  end
  x = x + 1;
  if pMatrizPesos[x][y] ~= nil then
    pCelula.dec = pMatrizPesos[x][y]+0;
    Potencial = Potencial + pMatrizPesos[x][y];
  else
    Erro = 1;
  end
  
  if Erro == 1 then
    print("Cálculo da favorabilidade INCONSISTENTE!");
  end
  
  Potencial = math.exp(Potencial)/(1 + math.exp(Potencial));
  return Potencial; 
end

-- PROGRAMA PRINCIPAL
-- configuracoes do modelo: limite de corte, elementos da equacao e quantidade a expandir.

-- Leitura do banco de dados espacial.
print("SIMULAÇÃO NO LITORAL NORTE PAULISTA");
print("Inicio:", os.date());
csP = CellularSpace{
dbType = "ADO",
host = "localhost",

database = "c:\\LNModelos\\LUCC\\LN.mdb", 
user = "",
password = "",
layer = "gradeLN",  
theme = "gradeLN",
select = {"et_id","object_id_","NF86","NF15","DNF86","DNF15","DROD86","DROD15","PROTEG","DDRENA","DECLIVI"}
}

csP:load();
print("Espaço celular lido: ",os.date());
CreateMooreNeighbourhood(csP);
print("Vizinhança Moore criada: ",os.date());
csP:synchronize();
print("BD sincronizado: ",os.date());

QtNeigbour, QtAlterado = calculaneig(cell);
QtNeigbourAux = {0,0,0,0,0,0,0,0,0};

-- le o arquivo de pesos na matriz Pesos x,y=linha,coluna
print("Vai ler o arquivo de pesos");
Pesos = lepesos("c:\\LNModelos\\LUCC\\lnpesosevidencia.dcf");
print("Leu arquivo de pesos");

-- chama função para cálculo da favorabilidade de transição e inicializa o atributo que armazenara o resultado da simulacao.
Pot = 0;
LimiteCorte = 0;
Corte = 0.94;
for i, cell in pairs(csP.cells) do
  if cell.past.NF15 == 1 then 
  -- 2015s:
  -- if cell.past.NF86 == 1 then 
  -- 2044s: 
  -- if cell.past.NF15 == 1 then
    Pot = calcula_potencial(cell,Pesos);
    cell.potencial = Pot;
    if Pot >= Corte then
      LimiteCorte = LimiteCorte + 1;
    end
  end
  cell.expande = cell.past.NF15;
  cell.NF44 = cell.past.NF15; 
  -- 2015s:
  -- cell.expande = cell.past.NF86;
  -- cell.NF15s = cell.past.NF86; 
  -- 2044s: 
  -- cell.expande = cell.past.NF15;
  -- cell.NF44 = cell.past.NF15; 
end
print("Quantidade de células selecionadas pelo limite de corte:",LimiteCorte);
csP:synchronize();
print("Preenchimento da favorabilidade nas células concluído: ", os.date());
-- ordena espaço celular pela favorabilidade de transição.
it = SpatialIterator {
csP,
function(cell) return (cell.NF44 == 1) end;  
-- 2015s: 
-- function(cell) return (cell.NF15s == 1) end; 
-- 2044s: 
-- function(cell) return (cell.NF44 == 1) end;

function(c1,c2) return c1.potencial > c2.potencial; end
}
print("Células ordenadas pela favorabilidade: ", os.date());
QtAnos = 29;
MediaAnualTrans = QtAlterado / QtAnos; -- Valor para simulacao inteira de uma vez

-- laço para os anos da simulação.
for time = 1, QtAnos, 1 do
  -- atualiza vetor de quantidade de transição de células por vizinhanca para o próximo passo.
  for cont = 1, 9, 1 do
    QtNeigbourAux[cont] = QtNeigbour[cont] / QtAnos; 
  end    
  print("Início da iteração número ", time," : ", os.date());
  cont = 0; 
  indireta = 0;
  saltadas = 0;
  Transicionou = true;
  -- laço para executar a transição das células.
  while (cont < MediaAnualTrans) and (Transicionou == true) do
    print("Espaço celular vai ser percorrido uma vez.");
    Transicionou = false;
    sequencial = 0;
    for i, cell in pairs(it.cells) do 
      QtDesmate = 0;
      ForEachNeighbour(cell,0,
        function(cell,neigh)
          if (neigh.past.NF44 == 2 and cell ~= neigh) then  -- 2015s: if (neigh.past.NF15s == 2 and cell ~= neigh) then ou 2044s: if (neigh.past.NF44 == 2 and cell ~= neigh) then 
            QtDesmate = QtDesmate + 1;  
          end
        end
      );
      -- condições para transição da célula.  
      Condicao0 = cell.past.NF44 == 1 and cell.NF44 == 1; -- 2015s: Condicao0 = cell.past.NF15s == 1 and cell.NF15s == 1; -- 2044s: Condicao0 = cell.past.NF44 == 1 and cell.NF44 == 1;
      Condicao1 = cont < MediaAnualTrans;
      Condicao2 = QtNeigbourAux[QtDesmate + 1] > 0; 
      -- parametros padrao do modelo: 4 e 1 foram os melhores para Acerto
      Condicao3 = math.random(0,100) <= (((1 / (LimiteCorte / MediaAnualTrans)) * 100) * 4) * math.exp(-(0.8 * (LimiteCorte ^ (-1))) * sequencial);
      sequencial = sequencial + 1;
      if Condicao0 and Condicao1 and Condicao2 and Condicao3 then
        cell.NF44 = 2; -- 2015s: cell.NF15s = 2; ou 2044s: cell.NF44 = 2; 
        cont = cont + 1;   
        QtNeigbourAux[QtDesmate + 1] = QtNeigbourAux[QtDesmate + 1] - 1;
        Transicionou = true;        
        alteravizinho = math.random(0,4);
        ForEachNeighbour(cell,0,
          function(cell,neigh)
            if (neigh.past.NF44 == 1 and neigh.NF44 == 1 and cell ~= neigh and alteravizinho > 0) then -- 2015s: if (neigh.past.NF15s == 1 and neigh.NF15s == 1 and cell ~= neigh and alteravizinho > 0) then ou 2044s: if (neigh.past.NF44 == 1 and neigh.NF44 == 1 and cell ~= neigh and alteravizinho > 0) then
              if neigh.past.potencial >= Corte and cont < MediaAnualTrans then
                QtDesmate = QtDesmate + 1;  
                neigh.NF44 = 2; -- 2015s: neigh.NF15s = 2; 2044s: neigh.NF44 = 2;
                cont = cont + 1;   
                alteravizinho = alteravizinho - 1;
                indireta = indireta + 1;
              end              
            end
          end
        );                
      else
        saltadas = saltadas + 1;
      end
    end
    csP:synchronize();
    print("Sincronize: ", os.date());
  end
  -- Relatório das alterações anuais.
  print("Quantidade de células alteradas no tempo ",time,":",cont);
  print("Quantidade de células que não atenderam as condições:",saltadas);
  if Transicionou == false then
    print("Necessitava transicionar mais mas não houve condições para isso.");
  end
  --csP:synchronize();
  --print("Sincronize: ", os.date());
  csP:save(time,"cellcnresult", {"NF86","NF15","PROTEG","DNF86","DNF15","DDRENA","DROD86","DROD15","DECLIVI","NF44","expande","potencial","prot","nflo15","dren","rod15","dec"}); -- 2015s: "NF15s" "nflo86" "rod86" ou 2044: "NF44" "nflo15" "rod15"
  print("Ano de simulacao: ", time);
end
-- gravação dos registros e encerramento da execução.
print("Fim do processamento:",os.date());