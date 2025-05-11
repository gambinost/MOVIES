from flask import Flask, request, jsonify
import joblib
import numpy as np

df = joblib.load('df.pkl')
df_encoded_scaled = joblib.load('df_encoded_scaled.pkl')
knn = joblib.load('knn_model.pkl')

app = Flask(__name__)

@app.route('/')
def home():
    return "🎬 Movie Recommendation System API is running!"

@app.route('/recommend_by_movie', methods=['GET'])
def recommend_by_movie():
    movie_title = request.args.get('title')
    k = int(request.args.get('k', 10))

    movie_index = df[df['title'] == movie_title].index
    if len(movie_index) == 0:
        return jsonify({"error": "Movie not found"}), 404

    index = movie_index[0]
    movie_features = df_encoded_scaled[index].reshape(1, -1)

    distances, indices = knn.kneighbors(movie_features, n_neighbors=k+1)
    indices = indices.flatten()[1:]  

    recommendations = df.iloc[indices][['title', 'overview', 'poster_path', 'tagline']]
    result = recommendations.to_dict(orient='records')

    return jsonify(result)

@app.route('/recommend_by_genre', methods=['GET'])
def recommend_by_genre():
    genre = request.args.get('genre')
    top_n = int(request.args.get('top_n', 10))

    filtered_df = df[df['genres'].str.contains(genre, case=False, na=False)].copy()

    if filtered_df.empty:
        return jsonify({"error": "Genre not found or no movies in this genre"}), 404

    for col in ['popularity', 'revenue', 'vote_average', 'vote_count', 'budget']:
        min_val = filtered_df[col].min()
        max_val = filtered_df[col].max()
        filtered_df[f'norm_{col}'] = (filtered_df[col] - min_val) / (max_val - min_val + 1e-9)

    filtered_df['composite_score'] = (
        0.2 * filtered_df['norm_popularity'] +
        0.2 * filtered_df['norm_revenue'] +
        0.2 * filtered_df['norm_vote_average'] +
        0.2 * filtered_df['norm_vote_count'] +
        0.2 * filtered_df['norm_budget']
    )

    top_movies = filtered_df.sort_values(by='composite_score', ascending=False).head(top_n)
    recommendations = top_movies[['title', 'overview', 'poster_path', 'tagline']]
    result = recommendations.to_dict(orient='records')

    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0') 
