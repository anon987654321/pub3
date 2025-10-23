# 📚 Chatbot Crew: Your Digital Wingman!

Welcome to the ultimate chatbot squad! 🚀 Here’s how each member of our squad operates and slays on their respective platforms:

## Overview

This repo contains code for automating tasks on Snapchat,
Tinder,
and Discord. Our chatbots are here to add friends,
send messages,
and even handle NSFW content with flair and humor.

## 🛠️ **Getting Set Up**

The code starts by setting up the necessary tools and integrations. Think of it as prepping your squad for an epic mission! 🛠️

```ruby
def initialize(openai_api_key)
  @langchain_openai = Langchain::LLM::OpenAI.new(api_key: openai_api_key)
  @weaviate = WeaviateIntegration.new
  @translations = TRANSLATIONS[CONFIG[:default_language].to_s]
end
```

## 👀 **Stalking Profiles (Not Really!)**

The code visits user profiles,
gathers all the juicy details like likes,
dislikes,
age,
and country,
and prepares them for further action. 🍵

```ruby
def fetch_user_info(user_id, profile_url)
  browser = Ferrum::Browser.new
  browser.goto(profile_url)
  content = browser.body
  screenshot = browser.screenshot(base64: true)
  browser.quit
  parse_user_info(content, screenshot)
end
```

## 🌟 **Adding New Friends Like a Boss**

It adds friends from a list of recommendations,
waits a bit between actions to keep things cool,
and then starts interacting. 😎

```ruby
def add_new_friends
  get_recommended_friends.each do |friend|
    add_friend(friend[:username])
    sleep rand(30..60)  # Random wait to seem more natural
  end
  engage_with_new_friends
end
```

## 💬 **Sliding into DMs**

The code sends messages to new friends,
figuring out where to type and click,
like a pro. 💬

```ruby
def send_message(user_id, message, message_type)
  puts "🚀 Sending #{message_type} message to #{user_id}: #{message}"
end
```

## 🎨 **Crafting the Perfect Vibe**

Messages are customized based on user interests and mood to make sure they hit just right. 💖

```ruby
def adapt_response(response, context)
  adapted_response = adapt_personality(response, context)
  adapted_response = apply_eye_dialect(adapted_response) if CONFIG[:use_eye_dialect]
  CONFIG[:type_in_lowercase] ? adapted_response.downcase : adapted_response
end
```

## 🚨 **Handling NSFW Stuff**

If a user is into NSFW content,
the code reports it and sends a positive message to keep things friendly. 🌟

```ruby
def handle_nsfw_content(user_id, content)
  report_nsfw_content(user_id, content)
  lovebomb_user(user_id)
end
```

## 🧩 **SnapChatAssistant**

Meet our Snapchat expert! 🕶️👻 This script knows how to slide into Snapchat profiles and chat with users like a boss.

### Features:
- **Profile Scraping**: Gathers info from Snapchat profiles. 📸
- **Message Sending**: Finds the right CSS classes to send messages directly on Snapchat. 📩
- **New Friend Frenzy**: Engages with new Snapchat friends and keeps the convo going. 🙌

## ❤️ **TinderAssistant**

Swipe right on this one! 🕺💖 Our Tinder expert handles all things dating app-related.

### Features:
- **Profile Scraping**: Fetches user info from Tinder profiles. 💌
- **Message Sending**: Uses Tinder’s CSS classes to craft and send messages. 💬
- **New Match Engagement**: Connects with new matches and starts the conversation. 🥂

## 🎮 **DiscordAssistant**

For all the Discord fans out there, this script’s got your back! 🎧👾

### Features:
- **Profile Scraping**: Gets the deets from Discord profiles. 🎮
- **Message Sending**: Uses the magic of CSS classes to send messages on Discord. ✉️
- **Friendship Expansion**: Finds and engages with new Discord friends. 🕹️

## Summary

1. **Setup:** Get the tools ready for action.
2. **Fetch Info:** Check out profiles and grab key details.
3. **Add Friends:** Add users from a recommendation list.
4. **Send Messages:** Slide into DMs with tailored messages.
5. **Customize Responses:** Adjust messages to fit the vibe.
6. **NSFW Handling:** Report and send positive vibes for NSFW content.

Boom! That’s how your Snapchat,
Tinder,
and Discord automation code works in Gen-Z style. Keep slaying! 🚀✨

Got questions? Hit us up! 🤙
