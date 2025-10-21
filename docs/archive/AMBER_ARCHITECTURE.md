# Amber Fashion Social Network Application

Amber Fashion is described as "the world's largest social network for fashion". Below are the features and technology stack utilized in the application:

## Features

1. **AI Wardrobe Import**  
   - Background removal  
   - Upscaling  
   - Relighting  
   - AI fashion models

2. **Mix & Match Magic**  
   - 4 StimulusComponent carousels rotating in opposite directions

3. **Closet Organization**  
   - Architecture plus interior design plus zen minimalism with smart algorithms

4. **Wardrobe Analytics**  
   - Usage tracking  
   - Cost-per-wear calculations  
   - Underutilized items visualization

5. **Style Assistant**  
   - Daily outfit suggestions

6. **Shop Smarter**  
   - Net-a-porter integration  
   - Affiliate products

7. **Social Features**  
   - User profiles  
   - Activity feed  
   - Anonymous posting  
   - Public chatroom  
   - Live webcam streaming

## Tech Stack

- PostgreSQL  
- Redis  
- Yarn  
- PWA  
- ActiveStorage  
- Devise  
- Falcon async server  
- ActionCable for real-time  
- AI integration  
- i18n (English and Norwegian)

## Generator Script

The generator script is `amber.sh`, which consists of 370 lines and utilizes the shared components pattern from the `__shared/` directory.

## Production Archive

The latest production archive is `rails_amber_20240806.tgz` with a size of 165KB.

## Models

- **Item**: Wardrobe items with attributes such as color, size, material, texture, brand, price.
- **Outfit**: User outfit combinations.
- **Posts**
- **Users**
- **Communities**
- **Comments**
- **Messages**
- **Notifications**

## Controllers

- **HomeController**  
- **FeaturesController**: Wardrobe, Style Assistant, Mix Match, Shop Smarter  
- **OutfitsController**  
- **RecommendationsController**  
- **SearchController**  
- **PostsController**  
- **LiveStreamController**