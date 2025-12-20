FROM ghcr.io/nokozan/aue-stage1-base-sd:cuda118-py310


WORKDIR /app

COPY . /app

# COPY requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir -r requirements_stage1.txt

# COPY handler.py /app/handler.py

# COPY src /app/src

# CMD ["python", "-u", "handler.py"]
CMD ["python3", "handler.py"]
