FROM python:3.10-slim

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо файл залежностей
COPY requirements.txt .

# Встановлюємо залежності Python
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код проекту
COPY . .

# Відкриваємо порт 8000 (Django за замовчуванням)
EXPOSE 8000

# Команда для запуску (використовуємо manage.py для простоти на іспиті)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
