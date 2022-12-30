-- Quais são as categorias de produtos que temos nesse banco de dados?
 select * from categories

-- Quais são os pedidos que temos nesse banco de dados?
select * from orders
limit 10

-- Qual o valor total por produto do meu estoque(total receita)?
 select 
	product_name,
	unit_price,
	units_in_stock,
	units_in_stock * unit_price as total_revenue
from products 


-- Quais funcionários são de Londres?
select * from employees
where city = 'London'
limit 10

-- Quais funcionários foram contratados antes de 1993?
select * from employees
where hire_date <= '1993-01-01'
limit 10

-- Quais funcionários com nomes começados pela letra M?
select * from employees
where first_name like 'M%'
limit 10

-- Quais funcionários trabalham com vendas?
select * from employees
where title like '%Sales%'
limit 10

-- Em cada venda, quanto arrecadamos com cada produto(revenue)?
-- select * from order_details
select *, unit_price * quantity as revenue
from order_details

/*
Funções Agregadas 
- Contagem
- Soma
- Média
- Máximo
- Mínimo
*/

-- Quanto foi vendido? Quantas unidades foram vendidas no total?
select sum(quantity) as total_unit_sold
from order_details

-- Quantas unidades de cada produto foi vendido?
select product_id, sum(quantity)
from order_details
group by product_id
-- Ordenando:
select product_id, sum(quantity) as total_units_sold
from order_details
group by product_id
-- order by total_units_sold
order by total_units_sold desc

-- Quantas vendas tivemos por mês?
select date_trunc('month', order_date) as order_month, count(order_id) 
from orders
group by order_month
order by order_month

-- Quais são os produtos que foram vendidos menos de 100 unidades? 
select product_id, sum(quantity) as total_units_sold
from order_details
group by product_id
having sum(quantity) <= 100
-- Ou quais venderam mais de 1000 unidades?
select product_id, sum(quantity) as total_units_sold
from order_details
group by product_id
having sum(quantity) >= 1000

/*
JOINS (Banco de dados relacionais-Postgres, SQL Server, MySQL, Oracle)
- Inner Join elemento existe em ambas as tabelas
- Left Join - considera tabela da esquerda como referência, se tiver correspondência na outra tabela ele traz, 
- se não tiver traz como nulo.
- Right Join - considera tabela da direita como referência, se tiver correspondência na outra tabela ele traz,
- se não tiver traz como nulo.
- Full Join - se tiver na tabela da direita ou da esquerda ele traz, se tiver correspondência traz com a 
- correspondência, se não correspondeu traz só o que ele tem, da esquerda ou da direita. 
*/
-- Qual é o nome das categorias dos produtos?
select 
	product_name,
	quantity_per_unit,
	unit_price,
	category_name,
	description
from products
inner join categories on 
categories.category_id = products.category_id

-- Quais são os pedidos que tiveram unidades vendidas em quantidades maiores que a média?
-- Calcular média: 
select avg(quantity) from order_details
-- Colocar a média como condição da busca por quantidades maiores que a média:
select * 
from order_details
where quantity > 
	(
		-- Subquery (cálculo da média)
		select avg(quantity) 
		from order_details
	)
-- Reescrevendo a query para que seja mais legível >>>
-- CTE -> Common Table Expression (Conjunto de tabelas que só existem enquanto o SQL está rodando.)
-- Definir a média (average):
with average as (
	select avg(quantity) as average_quantity
	from order_details
)
select order_details.* -- todas as colunas da talela order_details
from order_details, average
where quantity > average.average_quantity

/*
O índice pré ordena a tabela, otimizando a busca e fazendo as querys rodarem mais rápido:
- No Postgresql, por padrão, a chave primnária já tem índice associada a ela, mas é possível criar índice 
- para outras colunas. 
Tipos de índice:
- Árvore Binária
*/
-- Executando o select a seguir, observe o tempo em que demora para trazer os resultados:
select * from products
-- Adicionando indice na coluna de categorias (category_id):
create index idx_category on products(category_id)
-- Ao executar a busca a seguir agora usando o índice como filtro, é possível perceber que os resultados 
-- são retornados em menor tempo:
select *
from products
where category_id > 6
-- No exemplo anterior percebemos uma pequena alteração no tempo de execução, sendo assim, esta prática tem 
-- mais impacto em tabelas que possuem muitos dados.
-- Observação: Quando um elemento novo é adicionado, a tabela precisa se reorganizar como um todo e isso
-- gera um custo de processamento para o computador. Pensando no conceito de Leitura(quando estou consultando) 
-- e Escrita(quando estou adicionando dado na tabela) em banco de dados. Tabelas com índices leem mais rápido 
-- e escrevem mais devagar. Então é importante fazer sempre uma análise, a tabela em questão escreve mais do
-- que lê, se sim, adicionar índices pode ser perigoso, pois vai onerar meu sistema.
-- Por outro lado se minha tabela lê mais do que escreve, então vou ganhar performance, pois vou fazer a busca
-- em menos linhas e isso vai otimizar meu fluxo.
-- Pesquisar índices filtrados

 /*
-- Funções de janela
Existem 3 tipos de funções janela:
- Ranqueamento
- Agregação
- Posição
-- Pesquisar mais na documentação do PostgreSQL
*/
-- É possível responder as perguntas abaixo utilizando funções janela:
-- Qual produto o cliente comprou depois da primeira compra?
-- É possível saber o primeiro produto que um funcionário vendeu?
-- Primeiro passo, saber qual é a venda. Então primeiro vamos dar uma olhada na tabela:
select * from orders
-- Juntar as duas tabelas order e order_datails (nome do funcionário e data):
select *
from orders
inner join order_details on
orders.order_id = order_details.order_id
-- Reescrevendo a query, para selecionar as colunas que de fato precisamos:
select 
	employee_id,
	order_date,
	product_id
from orders
inner join order_details on
orders.order_id = order_details.order_id
-- Reescrevendo a query, para puxar o nome dos produtos ao invés do id dos produtos:
select 
	employee_id,
	order_date,
	product_name
from orders
inner join order_details on
	orders.order_id = order_details.order_id
inner join products on
	products.product_id = order_details.product_id
-- O que é Função de janela? É uma função que gera um valor dentro de uma janela e repete o valor em uma 
-- janela inteira.
-- Queremos saber o primieiro valor do order_date (qual foi a data que o funcionário fez a primeira venda dele)
-- e queremos ver isso em uma faicha (fazendo um agrupamento). Essa faicha é uma partição e ela é feita pelo 
-- employee_id, ou seja, pra cada funcionário eu quero que o valor do order_date seja sempre o first_value: 
select 
	employee_id,
	order_date, -- colocando aqui a coluna do order_date sem a função para entendermos como funciona.
	first_value(order_date) over (partition by employee_id order by order_date) as first_date,
	-- relacionando o produto também, nome de produto, funcionário a funcionário ordenado pela data:
		first_value(product_name) over (partition by employee_id order by order_date) as first_product
from orders
inner join order_details on
	orders.order_id = order_details.order_id
inner join products on
	products.product_id = order_details.product_id
-- Reescrevendo a query, retirando a coluna order_date e passando o comando distinct
select distinct
	employee_id,
	first_value(order_date) over (partition by employee_id order by order_date) as first_date,
	-- relacionando o produto também, nome de produto, funcionário a funcionário ordenado pela data:
		first_value(product_name) over (partition by employee_id order by order_date) as first_product
from orders
inner join order_details on
	orders.order_id = order_details.order_id
inner join products on
	products.product_id = order_details.product_id
-- Desta maneira conseguimos descobrir qual a primeira venda de cada funcionário e quando ela aconteceu.