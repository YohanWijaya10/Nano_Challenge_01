import SwiftUI

struct ContentView: View {
    @AppStorage("recipes") var recipesData: Data = Data()
    @State private var selectedRecipe: Recipe?
    @State private var recipes: [Recipe] = []
    @State private var isAddRecipeSheetPresented = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe), tag: recipe, selection: $selectedRecipe) {
                            HStack {
                                Text(recipe.name)
                                Spacer()
                                Text("Rp \(recipe.totalIngredientPrice, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Button(action: {
                    isAddRecipeSheetPresented.toggle()
                }) {
                    Text("Add Recipe")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isAddRecipeSheetPresented) {
                    AddRecipeView(recipes: $recipes)
                }
                
                Spacer()
            }
            .navigationTitle("Recipes")
            .onAppear {
                loadRecipesData()
            }
            .onChange(of: recipes) { recipes in
                saveRecipesData(recipes: recipes)
            }
        }
    }
    
    func saveRecipesData(recipes: [Recipe]) {
        do {
            let data = try JSONEncoder().encode(recipes)
            recipesData = data
        } catch {
            print("Error encoding recipes data: \(error)")
        }
    }
    
    func loadRecipesData() {
        do {
            recipes = try JSONDecoder().decode([Recipe].self, from: recipesData)
        } catch {
            print("Error decoding recipes data: \(error)")
        }
    }

    
}

struct Recipe: Identifiable, Equatable, Hashable , Codable {
    let id = UUID()
    let name: String
    let ingredients: [Ingredient]
    var totalIngredientPrice: Double {
        ingredients.reduce(0) { $0 + $1.price }
    }
    
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct AddRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var recipes: [Recipe]
    @AppStorage("recipes") var recipesData: Data = Data()
    @State private var recipeName = ""
    @State private var ingredientName = ""
    @State private var ingredientAmount = ""
    @State private var satuan = ""
    @State private var ingredientPrice = ""
    @State private var selectedOption = 0
    let options = ["gr", "ml", "tbsp" , "tsp" , "kg" , "L" , "oz" ]
    
    @State private var ingredients: [Ingredient] = []
    
    var totalIngredientPrice: Double {
        ingredients.reduce(0) { $0 + $1.price }
    }
    
    var formattedIngredientPrice: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        if let price = Double(ingredientPrice),
           let formattedPrice = numberFormatter.string(from: NSNumber(value: price)) {
            return formattedPrice
        }
        
        return ingredientPrice
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Recipe Details")) {
                        TextField("Recipe Name", text: $recipeName)
                    }
                    
                    VStack {
                        
                        TextField("Ingredient Name", text: $ingredientName)
                        HStack{
                            TextField("Amount", text: $ingredientAmount)
                                .keyboardType(.numberPad)
                            Picker("", selection: $selectedOption) {
                                ForEach(0..<options.count) { index in
                                    Text(options[index])
                                }
                            }
                        }
                        TextField("Price", text: $ingredientPrice )
                            .keyboardType(.decimalPad)
                        
                        
                    }
                    Button(action: addIngredient) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Section(header: Text("Ingredients")) {
                        ForEach(ingredients) { ingredient in
                            Text("\(ingredient.name) - \(ingredient.amount) \(ingredient.satuan) - Rp \(ingredient.price , specifier: "%.2f")")
                            
                        }
                    }
                    Text("Total: Rp \(totalIngredientPrice, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                }
                
                Button(action: saveRecipe) {
                    Text("Save Recipe")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .navigationTitle("Add Recipe")
        }
    }
    
    func addIngredient() {
        guard let amount = Int(ingredientAmount),
              let price = Double(ingredientPrice) else {
            return
        }
        
        let ingredient = Ingredient(name: ingredientName, amount: amount , satuan: options[selectedOption], price: price)
        ingredients.append(ingredient)
        
        ingredientName = ""
        ingredientAmount = ""
        ingredientPrice = ""
        
    }
    
    func saveRecipe() {
        guard !recipeName.isEmpty else {
            return
        }
        
        let recipe = Recipe(name: recipeName, ingredients: ingredients)
        recipes.append(recipe)
        
        
        
        
        
        presentationMode.wrappedValue.dismiss()
    }
}


struct Ingredient: Identifiable, Equatable, Hashable, Codable {
    let id = UUID()
    let name: String
    let amount: Int
    let satuan: String
    let price: Double
}

struct AddRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        AddRecipeView(recipes: .constant([]))
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack {
            Text(recipe.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical, 16)
            
            List(recipe.ingredients) { ingredient in
                VStack(alignment: .leading, spacing: 8) {
                    HStack{
                        Text(ingredient.name)
                            .font(.headline)
                        HStack{
                            Text(" \(ingredient.amount)")
                                .font(.subheadline)
                            Text(" \(ingredient.satuan)")
                                .font(.subheadline)
                                .padding(.leading, -10)
                        }
                    }
                    Text("Price: Rp \(ingredient.price , specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding([.top, .leading, .bottom], 8)
            }
            .listStyle(.plain)
            .padding(.horizontal, -16)
        }
        .navigationTitle("Recipe Detail")
    }
}
