import asyncio
import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
print("API Key:", api_key[:10] + "..." if api_key else None)

genai.configure(api_key=api_key)


async def test():
    model = genai.GenerativeModel("gemini-2.5-flash-thinking-exp")
    try:
        print("Calling gemini-2.5-flash-thinking-exp...")
        response = await model.generate_content_async("Hello")
        print("Response:", response.text)
    except Exception as e:
        print("Error with thinking-exp:", e)

    model_flash = genai.GenerativeModel("gemini-2.5-flash")
    try:
        print("Calling gemini-2.5-flash...")
        response = await model_flash.generate_content_async("Hello")
        print("Response:", response.text)
    except Exception as e:
        print("Error with flash:", e)


asyncio.run(test())
