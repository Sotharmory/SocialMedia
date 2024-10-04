from googletrans import Translator
from profanity_check import predict_prob

# Khởi tạo đối tượng Translator
translator = Translator()

# Danh sách từ khóa đen bao gồm cả tiếng Anh và tiếng Việt
blacklist_keywords = set([
    'fuck', 'shit', 'bitch', 'cunt', 'asshole', 'dick', 'pussy', 'motherfucker',
    'trungki', 'trungky', 'parki', 'parky', 'namki', 'namky',
    'lồn', 'vc', 'địt', 'cặc', 'bú', 'chịch'  # Thêm các từ khóa tục tĩu phổ biến
])

# Hàm dịch văn bản sang tiếng Anh
def translate_to_english(texts):
    translated_texts = []
    for text in texts:
        translated = translator.translate(text, src='auto', dest='en')
        translated_texts.append(translated.text)
        print(f"Original text: {text} | Translated text: {translated.text}")  # In ra văn bản gốc và đã dịch
    return translated_texts

# Hàm kiểm tra tính tục tĩu và từ khóa đen
def check_profanity_and_similarity(texts):
    translated_texts = translate_to_english(texts)
    print("Translated Texts:", translated_texts)  # In ra văn bản đã dịch để kiểm tra

    probabilities = predict_prob(translated_texts)
    print("Probabilities:", probabilities)  # In ra xác suất tục tĩu

    # Kiểm tra từ khóa đen trong văn bản gốc
    blacklisted_detected = []

    for text in texts:
        text_lower = text.lower()
        print("Checking text:", text_lower)  # In ra văn bản gốc để kiểm tra

        # Kiểm tra từ khóa đen trong văn bản gốc
        detected = any(keyword in text_lower for keyword in blacklist_keywords)
        print("Detected directly:", detected)  # In ra kết quả kiểm tra trực tiếp

        blacklisted_detected.append(detected)

    return probabilities, blacklisted_detected
