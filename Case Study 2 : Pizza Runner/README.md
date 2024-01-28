# **Case Study 2 : Pizza Runner**

![w2](https://github.com/dhana288/8-Week-SQL-Challenge/assets/111521363/0c527813-d765-42a3-8be9-45db9a64e043)

## **Introduction**

Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

## **Datasets**

- runners : The runners table shows the registration_date for each new runner
- customer_orders : Customer pizza orders are captured in the customer_orders table with 1 row for each individual pizza that is part of the order. The pizza_id relates to the type of pizza which was ordered whilst the exclusions are the ingredient_id values which should be removed from the pizza and the extras are the ingredient_id values which need to be added to the pizza. Note that customers can order multiple pizzas in a single order with varying exclusions and extras values even if the pizza is the same type! The exclusions and extras columns will need to be cleaned up before using them in your queries.
- runner_orders : After each orders are received through the system - they are assigned to a runner - however not all orders are fully completed and can be cancelled by the restaurant or the customer. The pickup_time is the timestamp at which the runner arrives at the Pizza Runner headquarters to pick up the freshly cooked pizzas. The distance and duration fields are related to how far and long the runner had to travel to deliver the order to the respective customer. There are some known data issues with this table so be careful when using this in your queries - make sure to check the data types for each column in the schema SQL!
- pizza_names : At the moment - Pizza Runner only has 2 pizzas available the Meat Lovers or Vegetarian!
- pizza_recipes : Each pizza_id has a standard set of toppings which are used as part of the pizza recipe.
- pizza_toppings : Each pizza_id has a standard set of toppings which are used as part of the pizza recipe.

## **Entity Relationship Diagram**

![image](https://github.com/dhana288/8-Week-SQL-Challenge/assets/111521363/0898d656-efe5-4550-a50c-48e961d47ebc)


